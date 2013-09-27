class SurveysController < ApplicationController
  # POST /surveys
  def create
    validation = Util.validate_creation params
    if validation[0]
      json = validation[1]
      user = validation[2]

      # validate surveys
      if json.keys.include?('surveys')
        response = [200, 'OK']

        # insert surveys
        surveys = json.fetch('surveys')
        unless surveys.blank?
          if surveys.kind_of?(Array)
            surveys.each do |node|
              # create Survey object
              survey = user.surveys.new(
                  :date => node['date'],
                  :question_1 => node['question1'],
                  :question_2 => node['question2'],
                  :question_3 => node['question3'],
                  :question_4 => node['question4'],
                  :question_5 => node['question5'],
                  :s_type => Util.get_param(node, 'type', 0)
              )
              # save Survey
              begin
                survey.save
              rescue => ex
                response = StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_UNABLE_CREATE, 'Survey', ex])
              end
            end
          else
            response = StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_INCOMPATIBLE_TYPE, 'surveys', 'Array'])
          end
        end
        render json: {:icat_status => response[0], :message => response[1]}
      else
        error = StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_ADDITIONAL_JSON, 'surveys'])
        render json: {:icat_status => error[0], :message => error[1]}
      end

    else
      render json: {:icat_status => validation[1], :message => validation[2]}
    end
  end

  # POST /surveys/query.json
  def query
    validation = Util.validate params
    if validation[0]
      json = validation[1]
      start_date = validation[2]
      end_date = validation[3] + 1.minute

      users = Util.validate_users json, Util::RESPONSE_TYPE_SURVEY

      total_time = (end_date - start_date + 1.day).round / 1.day

      # get survey type
      s_type = Util.get_param(json, 'type', 0)

      # clear invalid users
      users.reject! { |user| !user.valid }

      # for each user
      users.each do |user_response|
        user = user_response.user

        # if user does not exist
        unless user.nil?
          # query surveys inside date range
          #user_response.surveys = user.surveys.where(:date => start_date..end_date, :s_type => s_type, :question_1 => ).order('date ASC')
          user_response.surveys = user.surveys.where(:date => start_date..end_date, :s_type => s_type).order('date ASC')
          surveys_taken = user_response.surveys.where('question_1 != -1')
          user_response.surveys_taken = surveys_taken.count
          user_response.surveys_ignored = total_time - user_response.surveys_taken

          case s_type
            when 1 then
              sum = surveys_taken.sum(:question_1) + surveys_taken.sum(:question_2) + surveys_taken.sum(:question_3) + surveys_taken.sum(:question_4)
            when 2 then
              sum = surveys_taken.sum(:question_1) + surveys_taken.sum(:question_2)
            else
              sum = surveys_taken.sum { |s| s.question_1 / 2 } + surveys_taken.sum(:question_2) + surveys_taken.sum(:question_3) + surveys_taken.sum(:question_4) + surveys_taken.sum(:question_5)
          end

          user_response.avg_score = user_response.surveys_taken == 0 ? -1 : (sum.to_f / user_response.surveys_taken)
        end
      end

      users_with_avg = users.reject { |user| user.avg_score == -1 }

      render json: {
          :start_date => start_date.to_date.to_formatted_s(:db),
          :end_date => end_date.to_date.to_formatted_s(:db),
          :total_time => total_time,
          :avg_surveys_taken => '%0.1f' % (users.empty? ? -1 : (users.sum(&:surveys_taken).to_f / users.count())),
          :avg_surveys_ignored => '%0.1f' % (users.empty? ? -1 : (users.sum(&:surveys_ignored).to_f / users.count())),
          :avg_score => '%0.1f' % (users_with_avg.empty? ? -1 : (users_with_avg.sum(&:avg_score).to_f / users_with_avg.count())),
          :users => users.map { |user| {
              :username => user.username,
              :avg_score => '%0.1f' % user.avg_score,
              :surveys_taken => user.surveys_taken,
              :surveys_ignored => user.surveys_ignored,
              :surveys => user.surveys.map { |survey| {
                  :date => survey.date.to_date.to_formatted_s(:db),
                  #:question_1 => survey.question_1,
                  #:question_2 => survey.question_2,
                  #:question_3 => survey.question_3,
                  #:question_4 => survey.question_4,
                  #:question_5 => survey.question_5,
                  #:score => (survey.question_1 / 2).ceil + survey.question_2 + survey.question_3 + survey.question_4 + survey.question_5
              } },
          } },
          :icat_status => 200,
          :message => 'OK'
      }, :status => 200
    else
      render json: {:icat_status => validation[1], :message => validation[2]}
    end
  end
end