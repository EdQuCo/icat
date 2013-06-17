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
  #def edit
  #  @activity_count = ActivityCount.find(params[:id])
  #end

  # POST /activity_counts
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
          epoch = node['epoch']
          if epoch.blank?
            epoch = 60
          end

          charging = node['charging']
          if charging.blank?
            charging = false
          end

          # Create ActivityCount object
          activity_count = user.activity_counts.new(
              :date => node['date'],
              :counts => node['counts'],
              :epoch => epoch,
              :charging => charging)

          # Save ActivityCount
          begin
            activity_count.save
          rescue => ex
            status = 250
            message = "Unable to create one or more ActivityCount records. Last error: #{ex}"
          end
        end
        render json: {:icat_status => status, :message => message}
      else
        render json: {:icat_status => 401, :message => 'Must specify additional JSON parameters: activity_counts'}
      end
    else
      render json: {:icat_status => 400, :message => 'Must specify additional parameters: bundle'}
    end
  end

  # PUT /activity_counts/1
  #def update
  #  @activity_count = ActivityCount.find(params[:id])
  #
  #  respond_to do |format|
  #    if @activity_count.update_attributes(params[:activity_count])
  #      format.html { redirect_to @activity_count, notice: 'Activity count was successfully updated.' }
  #      format.json { head :no_content }
  #    else
  #      format.html { render action: 'edit' }
  #      format.json { render json: @activity_count.errors, status: :unprocessable_entity }
  #    end
  #  end
  #end

  # DELETE /activity_counts/1
  #def destroy
  #  @activity_count = ActivityCount.find(params[:id])
  #  @activity_count.destroy
  #
  #  respond_to do |format|
  #    format.html { redirect_to activity_counts_url }
  #    format.json { head :no_content }
  #  end
  #end

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
        bout_queue = Array.new(bout_size, -1)

        calories_algorithm = json['calories_algorithm']
        if calories_algorithm.blank?
          calories_algorithm = 'WILLIAMS98'
        end

        bmi = json['bmi']
        if bmi.blank?
          bmi = 25
        end

        # Create the Cut Point ranges
        intensities = []
        if json.keys.include?('cut-point-ranges')
          ranges = json.fetch('cut-point-ranges')
          min = 0
          ranges.each do |intensity|
            max = intensity['max']
            intensities << Intensity.new(intensity['name'], min, max)
            min = intensity['max'] + 1
          end
        else
          cut_point_set = json['cut-point-set']
          if cut_point_set.blank?
            cut_point_set = 'DEFAULT'
          end
          intensities = ActivityUtil.build_intensities cut_point_set
        end

        # Initiate variables
        total_counts = 0
        off_time = 0
        nonwear_time = 0
        date = start_date

        # Query activity counts inside date range
        activity_counts = user.activity_counts.where(:date => start_date..end_date)

        # iterate through activity counts
        activity_counts.each do |activity_count|
          off_time += (activity_count.date - date).round / 1.minute
          #puts "Comparing #{activity_count.date} vs #{date}: OFF TIME: #{off_time}"

          counts = activity_count.counts

          # append total counts
          total_counts += counts

          # classify epoch
          if activity_count.charging
            nonwear_time += 1
          else
            intensities.each_with_index do |intensity, index|
              if intensity.in_range?(counts)
                intensity.add_counts(counts)
                intensity.add_time(1)
                intensity.add_calories(ActivityUtil.compute_calories calories_algorithm, counts, bmi)
                #puts "this count: #{activity_count.date} (#{activity_count.counts}) belongs to #{intensity.name}"
                break
              end
            end
          end

          # adjust date
          date = activity_count.date + 1.minute
        end

        #puts ActivityUtil.compute_epoch_sleep_score activity_counts, 0, 'COLE_KRIPKE'

=begin
        intensities.each do |intensity|
          puts "name: #{intensity.name}, counts: #{intensity.counts}, bouts: #{intensity.bouts}, minutes: #{intensity.time}"
        end
=end

        total_time = (end_date - start_date).round / 1.minute
        off_time += (end_date - date).round / 1.minute
        total_calories = ActivityUtil.compute_calories calories_algorithm, total_counts, bmi

        #Util.compute_sleep_score activity_counts, start_date, end_date
        render json: {
            :username => username,
            :start_date => start_date.to_formatted_s(:db),
            :end_date => end_date.to_formatted_s(:db),
            :total_time => total_time,
            :total_counts => total_counts,
            :total_calories => total_calories,
            :intensities => intensities.map { |intensity| {
                :name => intensity.name,
                :counts => intensity.counts,
                :time => intensity.time,
                :bouts => intensity.bouts,
                :calories => intensity.calories
            } },
            :nonwear_time => nonwear_time,
            :off_time => off_time,
            :code => 200,
            :message => 'OK'
        }, :status => 200
      end

    else
      render json: {:icat_status => 400, :message => 'Must specify additional parameters: bundle'}
    end
  end

  # POST /activity_counts/query_sleep_score.json
  def query_sleep_score
    if params.has_key?(:bundle)
      begin
        json = JSON.parse(params[:bundle])
      rescue => ex
        render json: {:icat_status => 402, :message => "JSON Parse error. Details: #{ex}"}
        return
      end

      # validate API-key
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

      # validate username
      username = json['username']
      if username.blank?
        render json: {:icat_status => 401, :message => 'Must specify additional JSON parameters: username'}
        return
      end

      user = User.find_by_username(username)
      # if user does not exist
      if user.nil?
        render json: {:icat_status => 403, :message => "User #{username} does not exist"}
        return
      else
        start_date = json['start_date']
        if start_date.blank?
          render json: {:icat_status => 401, :message => 'Must specify additional JSON parameters: start_date'}
          return
        else
          begin
            start_date = DateTime.parse(start_date).to_time
          rescue => ex
            render json: {:icat_status => 402, :message => "JSON Parse error. Details: #{ex}"}
            return
          end
        end

        end_date = json['end_date']
        if end_date.blank?
          render json: {:icat_status => 401, :message => 'Must specify additional JSON parameters: end_date'}
          return
        else
          begin
            end_date = DateTime.parse(end_date).to_time
          rescue => ex
            render json: {:icat_status => 402, :message => "JSON Parse error. Details: #{ex}"}
            return
          end
        end

        algorithm = json['algorithm']
        if algorithm.blank?
          algorithm = ActivityUtil::SS_ALGORITHM_FASTEST
        end

        sleep_threshold = json['sleep_threshold']
        if sleep_threshold.blank?
          sleep_threshold = ActivityUtil::SLEEP_THRESHOLD
        end

        # Initiate variables
        sleep_onset = []
        total_sleep_time = 0
        awakenings = 0
        avg_awakening_time = 0
        sleep_scores = []
        epoch_index = 0

        total_counts = 0
        nonwear_time = 0
        off_time = 0

        date = start_date

        # query activity counts inside date range
        activity_counts = user.activity_counts.where(:date => start_date..end_date).order('date ASC')

        # iterate through activity counts
        activity_counts.each_with_index do |activity_count, index|
          time_offset = (activity_count.date - date).round / 1.minute
          off_time += time_offset

          #epoch_queue.push

          if time_offset != 0
            #puts "Comparing #{activity_count.date} vs #{date}: OFF TIME: #{time_offset}"
            #puts time_offset
            #sleep_scores.push(Array.new(time_offset, 0)).flatten!

            # the filled values will share the same date
            sleep_scores.push(Array.new(time_offset, SleepScore.new(activity_count.date, -1, false))).flatten!
          end

          counts = activity_count.counts

          # append total counts
          total_counts += counts

          # classify epoch
          if activity_count.charging
            nonwear_time += 1
            sleep_scores << SleepScore.new(activity_count.date, 0, false)
          else
            #sleep_scores << ActivityUtil.compute_epoch_sleep_score(activity_counts, index, algorithm, sleep_threshold)
            sleep_scores << SleepScore.new(activity_count.date, activity_count.counts, true)
          end

          # adjust date
          date = activity_count.date + 1.minute

          # adjust
          if time_offset != 0
            epoch_index += time_offset
            # TODO ADJUST
          end
          epoch_index += 1
        end

        # analyze epoch scores
        # D = 0.00001(404 * A_(-4) + 598 * A_(-3) + 326 * A_(-2) + 441 * A_(-1) + 1408 * A_0 + 508 * A_(+1) + 350 * A_(+2))
        epoch_queue = Array.new(7, SleepScore.new(start_date, 0, false))
        epoch_queue.push(sleep_scores.shift(3)).flatten!
        sleep_scores.each do |sleep_score|
          epoch_queue << sleep_score
          score = ActivityUtil.compute_epoch_sleep_score(epoch_queue, 4, algorithm, sleep_threshold)
          puts "scored as #{score}"
          epoch_queue.shift
        end
        total_sleep_time = sleep_scores.find_all{|item| !item.valid}.size
        total_awake_time = sleep_scores.size - total_sleep_time

        puts "Sleep time #{total_sleep_time}, awake time #{total_awake_time}"

        # if rescoring
        if algorithm == ActivityUtil::SS_ALGORITHM_COLE_KRIPKE
          # TODO RESCORE
        end

        total_time = (end_date - start_date).round / 1.minute
        if end_date > date
          off_time += (end_date - date).round / 1.minute
          puts "Comparing #{end_date} vs #{date}: OFF TIME: #{off_time}"
        end


        render json: {
            :username => username,
            :start_date => start_date.to_formatted_s(:db),
            :end_date => end_date.to_formatted_s(:db),
            :total_time => total_time,
            :total_counts => total_counts,
            :total_sleep_time => total_sleep_time,
            :total_awake_time => total_awake_time,
            :awakenings => awakenings,
            :avg_awakening_time => avg_awakening_time,
            :sleep_onset => sleep_onset.to_json,
            #:intensities => intensities.map { |intensity| {
            #    :name => intensity.name,
            #    :counts => intensity.counts,
            #    :time => intensity.time,
            #    :bouts => intensity.bouts,
            #    :calories => intensity.calories
            #} },
            :nonwear_time => nonwear_time,
            :off_time => off_time,
            :code => 200,
            :message => 'OK'
        }, :status => 200
      end

    else
      render json: {:icat_status => 400, :message => 'Must specify additional parameters: bundle'}
    end
  end
end
