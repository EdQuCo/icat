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
    if params.has_key?(:bundle)
      begin
        json = JSON.parse(params[:bundle])
      rescue => ex
        render json: {:icat_status => 402, :message => "JSON Parse error. Details: #{ex}"}, :status => 400
        return
      end

      # Validate API-key
      api_key = json['api_key']
      if api_key.blank?
        render json: {:icat_status => 401, :message => 'Must specify additional JSON parameters: api_key'}, :status => 400
        return
      else
        #TODO Match API-key
        # if wrong api key, raise icat_error x
      end

      # Validate username
      username = json['username']
      if username.blank?
        render json: {:icat_status => 401, :message => 'Must specify additional JSON parameters: username'}, :status => 400
        return
      end

      user = User.find_by_username(username)
      # If user does not exist
      if user.nil?
        render json: {:icat_status => 403, :message => "User #{username} does not exist"}, :status => 400
        return
      else
        start_date = json['start_date']
        if start_date.blank?
          render json: {:icat_status => 401, :message => 'Must specify additional JSON parameters: start_date'}, :status => 400
          return
        else
          begin
            start_date = DateTime.parse(start_date).to_time
          rescue => ex
            render json: {:icat_status => 402, :message => "JSON Parse error. Details: #{ex}"}, :status => 400
            return
          end
        end

        end_date = json['end_date']
        if end_date.blank?
          render json: {:icat_status => 401, :message => 'Must specify additional JSON parameters: end_date'}, :status => 400
          return
        else
          begin
            end_date = DateTime.parse(end_date).to_time
          rescue => ex
            render json: {:icat_status => 402, :message => "JSON Parse error. Details: #{ex}"}, :status => 400
            return
          end
        end

        # Query surveys inside date range
        surveys = user.surveys.where(:date => start_date..end_date)

        # TODO: Fix date format
        render json: {
            :username => username,
            :start_date => start_date.to_formatted_s(:db),
            :end_date => end_date.to_formatted_s(:db),
            :surveys => surveys.as_json(:except => [:id, :user_id]),
            #:surveys => surveys.map { |survey| {
            #    :name => intensity.name,
            #    :counts => intensity.counts,
            #    :time => intensity.time,
            #    :bouts => intensity.bouts,
            #    :calories => intensity.calories
            #} },
            :code => 200,
            :message => 'OK'
        }, :status => 200
      end

    else
      render json: {:icat_status => 400, :message => 'Must specify additional parameters: bundle'}
    end
  end
end