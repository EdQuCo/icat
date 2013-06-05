class ActivityCountsController < ApplicationController
  # GET /activity_counts
  # GET /activity_counts.json
  #def index
  #  @activity_counts = ActivityCount.all
  #
  #  respond_to do |format|
  #    format.html # index.html.erb
  #    format.json { render json: @activity_counts }
  #  end
  #end

  # GET /activity_counts/1
  # GET /activity_counts/1.json
  #def show
  #  @activity_count = ActivityCount.find(params[:id])
  #
  #  respond_to do |format|
  #    format.html # show.html.erb
  #    format.json { render json: @activity_count }
  #  end
  #end

  # GET /activity_counts/new
  # GET /activity_counts/new.json
  #def new
  #  @activity_count = ActivityCount.new
  #
  #  respond_to do |format|
  #    format.html # new.html.erb
  #    format.json { render json: @activity_count }
  #  end
  #end

  # GET /activity_counts/1/edit
  def edit
    @activity_count = ActivityCount.find(params[:id])
  end

  # POST /activity_counts
  def create
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

      # Validate activity counts
      if json.keys.include?('activity_counts')
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

        # Insert each activity count
        counts = json.fetch('activity_counts')
        counts.each do |node|
          # Create ActivityCount object
          activity_count = user.activity_counts.new(
              :date => node['date'],
              :counts => node['counts'],
              :epoch => node['epoch'],
              :charging => node['charging'])

          # Save ActivityCount
          begin
            activity_count.save
          rescue => ex
            status = 250
            message = "Unable to create one or more ActivityCount records. Last error: #{ex}"
          end
        end
        render json: {:icat_status => status, :message => message}, :status => 200
      else
        render json: {:icat_status => 401, :message => 'Must specify additional JSON parameters: activity_counts'}, :status => 400
        #return
      end
    else
      render json: {:icat_status => 400, :message => 'Must specify additional parameters: bundle'}, :status => 400
    end

    #render json: {:counts => activity_counts.as_json(:only => [:charging]), :total_counts => total_counts, :total_calories => total_calories, :nonwear_time => nonwear_time, :code => off_time}
  end

  # PUT /activity_counts/1
  def update
    @activity_count = ActivityCount.find(params[:id])

    respond_to do |format|
      if @activity_count.update_attributes(params[:activity_count])
        format.html { redirect_to @activity_count, notice: 'Activity count was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @activity_count.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /activity_counts/1
  def destroy
    @activity_count = ActivityCount.find(params[:id])
    @activity_count.destroy

    respond_to do |format|
      format.html { redirect_to activity_counts_url }
      format.json { head :no_content }
    end
  end

  # POST /activity_counts/query.json
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

        bout_allowance = json['bout_allowance']
        if bout_allowance.blank?
          bout_allowance = 2
        end

        bout_size = json['bout_size']
        if bout_size.blank?
          bout_size = 10
        end

        intensities = []
        if json.keys.include?('cut-point-ranges')
          ranges = json.fetch('cut-point-ranges')

          # Create the Cut Point ranges

          min = 0
          ranges.each do |intensity|
            max = intensity['max']
            intensities << Intensity.new(intensity['intensity'], min, max)
            min = intensity['max'] + 1
          end
        else
          intensities << Intensity.new('sedentary', 0, 99)
          intensities << Intensity.new('light', 100, 1951)
          intensities << Intensity.new('moderate', 1952, 5724)
          intensities << Intensity.new('hard', 5725, 99999)
        end

        # Initiate variables
        total_counts = 0
        total_calories = 0
        off_time = 0
        nonwear_time = 0
        date = start_date

        # Query activity counts inside date range
        activity_counts = user.activity_counts.where(:date => start_date..end_date)

        # iterate through activity counts
        activity_counts.each do |activity_count|
          off_time += (activity_count.date - date).round / 1.minute
          puts "Comparing #{activity_count.date} vs #{date}: OFF TIME: #{off_time}"

          counts = activity_count.counts

          # append total counts
          total_counts += counts

          # classify epoch
          if activity_count.charging
            nonwear_time += 1
          else

          end

          intensities.each do |intensity|
            if intensity.in_range?(counts)
              intensity.add_counts(counts)
              puts "this count: #{activity_count.date} (#{activity_count.counts}) belongs to #{intensity.name}"
              break
            end
          end

          # adjust date
          date = activity_count.date + 1.minute
        end

        off_time += (end_date - date).round / 1.minute

        intensities.each do |intensity|
          puts "name: #{intensity.name}, counts: #{intensity.counts}, bouts: #{intensity.bouts}, minutes: #{intensity.time}"
        end

        algorithm = json['calories_algorithm']
        total_calories = Util.compute_calories total_counts, algorithm

        puts total_calories

        #Util.compute_sleep_score activity_counts, start_date, end_date
        render json: {:total_counts => total_counts,
                      :total_calories => total_calories,
                      :nonwear_time => nonwear_time,
                      :off_time => off_time,
                      :intensities => intensities.map { |intensity| {
                          :name => intensity.name,
                          :counts => intensity.counts,
                          :time => intensity.time,
                          :bouts => intensity.bouts,
                          :calories => intensity.calories
                      }},
                      :code => 200,
                      :message => 'OK',
                      :start_date => start_date.to_formatted_s(:db),
                      :end_date => end_date.to_formatted_s(:db)
        }

        #render json: {:icat_status => 200, :message => 'Message', :counts => activity_counts.as_json}, :status => 200
      end

    else
      render json: {:icat_status => 400, :message => 'Must specify additional parameters: bundle'}, :status => 400
    end
  end
end
