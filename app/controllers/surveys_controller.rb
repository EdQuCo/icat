class SurveysController < ApplicationController
  # POST /surveys
  def create
    if params.has_key?(:bundle)
      begin
        json = JSON.parse(params[:bundle])
      rescue => ex
        render json: {:icat_status => 402, :message => "JSON Parse error. Details: #{ex}"}
        return
      end

      # Validate API-key
      api_key = json['api_key']
      if api_key.blank?
        render json: {:icat_status => 401, :message => 'Must specify additional JSON parameters: api_key'}
        return
      else
        if api_key != 'iCAT-2013-1234567890'
          render json: {:icat_status => 404, :message => 'Wrong API-Key'}
          return
        end
      end

      # Validate username
      username = json['username']
      if username.blank?
        render json: {:icat_status => 401, :message => 'Must specify additional JSON parameters: username'}
        return
      end

      # Validate surveys
      if json.keys.include?('surveys')
        # Query user by username
        user = User.find_by_username(username)
        # If user doesn't exist, create a new one
        if user.nil?
          user = User.new(:username => username)
          begin
            user.save
          rescue => ex
            render json: {:icat_status => 500, :message => "Unable to create user #{username}: #{ex}"}, :status => 500
            return
          end
        end

        status = 200
        message = 'OK'

        # Insert each survey
        surveys = json.fetch('surveys')
        surveys.each do |node|
          # Create Survey object
          survey = user.surveys.new(
              :date => node['date'],
              :question_1 => node['question1'],
              :question_2 => node['question2'],
              :question_3 => node['question3'],
              :question_4 => node['question4'],
              :question_5 => node['question5'])

          # Save Survey
          begin
            survey.save
          rescue => ex
            status = 250
            message = "Unable to create one or more Survey records. Last error: #{ex}"
          end
        end
        render json: {:icat_status => status, :message => message}
      else
        render json: {:icat_status => 401, :message => 'Must specify additional JSON parameters: surveys'}
      end
    else
      render json: {:icat_status => 400, :message => 'Must specify additional parameters: bundle'}
    end
  end

  # POST /surveys/query.json
  def query
    validation = Util.validate params
    if validation[0]
      json = validation[1]
      user = validation[2]
      start_date = validation[3]
      end_date = validation[4]

      # Query surveys inside date range
      surveys = user.surveys.where(:date => start_date..end_date)
      #surveys_taken = surveys.where('question_1 != -1')

      render json: {
          :username => user.username,
          :start_date => start_date.to_date.to_formatted_s(:db),
          :end_date => end_date.to_date.to_formatted_s(:db),
          :surveys => surveys.map { |survey| {
              :date => survey.date.to_date.to_formatted_s(:db),
              :score => survey.question_1 + survey.question_2 + survey.question_3 + survey.question_4 + survey.question_5
          } },
          :icat_status => 200,
          :message => 'OK'
      }, :status => 200

    else
      render json: {:icat_status => validation[1], :message => validation[2]}
    end
  end
end