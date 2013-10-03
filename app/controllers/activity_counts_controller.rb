class ActivityCountsController < ApplicationController

  # POST /activity_counts
  def create
    validation = Util.validate_creation params
    if validation[0]
      json = validation[1]
      user = validation[2]

      # validate activity counts
      if json.keys.include?('activity_counts')
        response = [200, 'OK']

        # insert activity counts
        activity_counts = json.fetch('activity_counts')
        unless activity_counts.blank?
          if activity_counts.kind_of?(Array)
            inserts = []
            insertion_error = false

            activity_counts.each do |node|
              epoch = Util.get_param(node, 'epoch', 60)
              charging = Util.get_param(node, 'charging', false)
              steps = Util.get_param(node, 'steps', 0)

              inserts.push "(#{user.id}, '#{node['date']}', #{node['counts']}, #{epoch}, '#{charging}', '#{steps}')"
            end

            sql = "INSERT INTO activity_counts (user_id, date, counts, epoch, charging, steps) VALUES #{inserts.join(', ')}"
            begin
              ActiveRecord::Base.connection.execute(sql)
            rescue => ex
              insertion_error = true
            end

            if insertion_error
              activity_counts.each do |node|
                epoch = Util.get_param(node, 'epoch', 60)
                charging = Util.get_param(node, 'charging', false)
                steps = Util.get_param(node, 'steps', 0)

                # create ActivityCount object
                activity_count = user.activity_counts.new(
                    :date => node['date'],
                    :counts => node['counts'],
                    :epoch => epoch,
                    :charging => charging,
                    :steps => steps)

                # save ActivityCount
                begin
                  activity_count.save
                rescue => ex
                  response = StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_UNABLE_CREATE, 'ActivityCount', ex])
                end
              end
            end

          else
            response = StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_INCOMPATIBLE_TYPE, 'activity_counts', 'Array'])
          end
        end
        render json: {:icat_status => response[0], :message => response[1]}
      else
        error = StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_ADDITIONAL_JSON, 'activity_counts'])
        render json: {:icat_status => error[0], :message => error[1]}
      end

    else
      render json: {:icat_status => validation[1], :message => validation[2]}
    end
  end

  # POST /activity_counts/query.json
  def query
    validation = Util.validate params
    if validation[0]
      json = validation[1]
      start_date = validation[2]
      end_date = validation[3] - 1.minute

      users = Util.validate_users json, Util::RESPONSE_TYPE_ACTIVITY
      calories_algorithm = Util.get_param(json, 'calories_algorithm', ActivityUtil::DEF_CAL_ALGORITHM)
      calories_scale = Util.get_param(json, 'calories_scale', ActivityUtil::DEF_CAL_SCALE)

      compute_bouts = Util.get_param(json, 'compute_bouts', 0)
      bout_size = Util.get_param(json, 'bout_size', ActivityUtil::DEF_BOUT_SIZE)
      bout_allowance = Util.get_param(json, 'bout_allowance', ActivityUtil::DEF_BOUT_ALLOWANCE)

      # create the Cut-Point ranges
      intensities = []
      if json.keys.include?('cut-point-ranges')
        ranges = json.fetch('cut-point-ranges')
        min = 0
        index = 0
        #TODO validate array
        ranges.each do |intensity|
          #max = intensity['max']
          max = Util.get_param(intensity, 'max', min + 1000)
          max = min + 1000 if max <= min
          name = Util.get_param(intensity, 'name', 'unnamed_range')
          #intensities << Intensity.new(intensity['name'], min, max)
          intensities << Intensity.new(index, name, min, max)
          min = max + 1
          index += 1
        end
      else
        cut_point_set = Util.get_param(json, 'cut-point-set', ActivityUtil::DEF_CUT_POINTS_SET)
        intensities = ActivityUtil.build_intensities cut_point_set
      end

      total_time = (end_date - start_date + 1.minute).round / 1.minute

      # clear invalid users
      users.reject! { |user| !user.valid }

      # for each user
      users.each do |user_response|
        user = user_response.user

        # set empty intensities
        user_response.intensities = Util.deep_copy(intensities)

        # if user does not exist
        unless user.nil?
          # query activity counts inside date range
          # NOTE: At this moment, we don't need to order the results. Be careful if code is modified (.order('date ASC')).
          activity_counts = user.activity_counts.where(:date => start_date..end_date)

          if compute_bouts != 0
            ActivityUtil.get_bouts(activity_counts, bout_size, bout_allowance, user_response.intensities)
          end

          user_response.intensities.each do |intensity|
            counts_in_range = activity_counts.where(:charging => 'false', :counts => intensity.min..intensity.max)
            intensity.counts = counts_in_range.sum(:counts)
            intensity.steps = counts_in_range.sum(:steps)
            intensity.time = counts_in_range.count()
            intensity.calories = ActivityUtil.compute_calories(calories_algorithm, intensity.counts, user_response.bmi, calories_scale)
          end

          user_response.total_counts = activity_counts.sum(:counts)
          user_response.total_steps = activity_counts.sum(:steps)
          user_response.on_time = activity_counts.count()
          user_response.nonwear_time = activity_counts.count(:conditions => 'charging = true')
          user_response.wear_time = user_response.on_time - user_response.nonwear_time
          user_response.total_time = total_time
          user_response.off_time = total_time - user_response.on_time
          user_response.total_calories = ActivityUtil.compute_calories(calories_algorithm, user_response.total_counts, user_response.bmi, calories_scale)
        end
      end

      render json: {
          :start_date => start_date.to_formatted_s(:db),
          :end_date => (end_date + 1.minute).to_formatted_s(:db),
          :total_time => total_time,
          :avg_counts => (users.empty? ? 0 : (users.sum(&:total_counts) / users.count())).ceil,
          :avg_calories => (users.empty? ? 0 : (users.sum(&:total_calories) / users.count())).ceil,
          :avg_steps => (users.empty? ? 0 : (users.sum(&:total_steps) / users.count())).ceil,
          :users => users.map { |user| {
              :username => user.username,
              :bmi => user.bmi,
              :total_counts => user.total_counts,
              :total_calories => user.total_calories.ceil,
              :total_steps => user.total_steps,
              :intensities => user.intensities.map { |intensity| {
                  :name => intensity.name,
                  :counts => intensity.counts,
                  :time => intensity.time,
                  :bouts => intensity.bouts,
                  :calories => intensity.calories.ceil,
                  :steps => intensity.steps
              } },
              :wear_time => user.wear_time,
              :nonwear_time => user.nonwear_time,
              :off_time => user.off_time,
              :on_time => user.on_time,
          } },
          :avg_wear_time => (users.empty? ? 0 : (users.sum(&:wear_time) / users.count())).ceil,
          :avg_nonwear_time => (users.empty? ? 0 : (users.sum(&:nonwear_time) / users.count())).ceil,
          :avg_on_time => (users.empty? ? 0 : (users.sum(&:on_time) / users.count())).ceil,
          :avg_off_time => (users.empty? ? 0 : (users.sum(&:off_time) / users.count())).ceil,
          :icat_status => 200,
          :message => 'OK'
      }, :status => 200

    else
      render json: {:icat_status => validation[1], :message => validation[2]}
    end
  end

  # POST /activity_counts/query_sleep_score.json
  def query_sleep_score
    validation = Util.validate params
    if validation[0]
      json = validation[1]
      start_date = validation[2]
      end_date = validation[3] - 1.minute

      users = Util.validate_users json, Util::RESPONSE_TYPE_SLEEP

      algorithm = Util.get_param(json, 'algorithm', ActivityUtil::DEF_SS_ALGORITHM)
      algorithm_params = Util.get_array_param(json, 'algorithm_params', ActivityUtil.get_ss_algorithm_params(algorithm))
      sleep_onset_threshold = Util.get_param(json, 'sleep_onset_threshold', ActivityUtil::DEF_SLEEP_ONSET_THRESHOLD)
      wake_onset_threshold = Util.get_param(json, 'wake_onset_threshold', ActivityUtil::DEF_AWAKE_ONSET_THRESHOLD)

      # clear invalid users
      users.reject! { |user| !user.valid }

      total_time = (end_date - start_date + 1.minute).round / 1.minute

      # for each user
      users.each do |user_response|
        user = user_response.user

        # if user does not exist
        unless user.nil?
          # query activity counts inside date range
          activity_counts = user.activity_counts.where(:date => start_date..end_date).order('date ASC')

          date = start_date
          # initialize sleep scores (empty epochs will be filled with 'invalid' scores)
          sleep_scores = []
          activity_counts.each do |activity_count|
            time_offset = ((activity_count.date - date) / 1.minute + 0.5).floor

            if time_offset != 0
              #puts "#{activity_count.date} vs #{date} => #{(activity_count.date - date)} - #{(activity_count.date - date).round} - #{(activity_count.date - date) / 1.minute} - #{((activity_count.date - date) / 1.minute + 0.5).floor}"
              #puts "time offset: #{time_offset}"
              # the filled values will share the same date (could this be a problem?)
              sleep_scores.push(Array.new(time_offset, SleepScore.new(activity_count.date, 0, false))).flatten!
            end
            sleep_scores << SleepScore.new(activity_count.date, activity_count.counts, true)

            # adjust date
            date = (activity_count.date + 1.minute).change({:sec => 0})
          end

          # analyze epoch scores
          epoch_queue = Array.new(4, SleepScore.new(start_date, 0, false))
          epoch_queue.push(sleep_scores.first(2)).flatten!

          sleep_scores.each do |sleep_score|
            epoch_queue << sleep_score
            sleep_score.score = ActivityUtil.compute_epoch_sleep_score(epoch_queue, 4, algorithm, algorithm_params)
            epoch_queue.shift
          end

          #beginning = Time.now

          # rescore if requested
          if algorithm == ActivityUtil::SS_ALGORITHM_COLE_KRIPKE
            # after at least 4 minutes scored as wake,
            # the next 1 minute scored as sleep is rescored as wake.
            ActivityUtil.rescore(sleep_scores, 1, 4)
            # after at least 10 minutes scored as wake,
            # the next 3 minutes scored as sleep are rescored as wake
            ActivityUtil.rescore(sleep_scores, 3, 10)
            # after at least 15 minutes scored as wake,
            # the next 4 minutes scored as sleep are rescored as wake
            ActivityUtil.rescore(sleep_scores, 4, 15)
            # 6 minutes or less scored as sleep surrounded by at least 10 minutes
            # (before and after) scored as wake are rescored as wake
            ActivityUtil.rescore_with_neighbors(sleep_scores, 6, 10)
            # 10 minutes or less scored as sleep surrounded by at least 20 minutes (before and after) scored as wake are rescored as wake
            # (before and after) scored as wake are rescored as wake
            ActivityUtil.rescore_with_neighbors(sleep_scores, 10, 20)
          end

          # find asleep and awake onsets
          # onset indexes: 0 -> score, 1 -> date, 2 -> global index
          onsets = []
          # -1 -> undefined, 0 -> awake, 1 -> asleep
          previous_state = -1
          sleep_scores.each_with_index.chunk { |sleep_score, i|
            sleep_score.score == ActivityUtil::AWAKE
          }.map do |is_awake, pairs|
            # 'pair' -> [SleepScore object, index in sleep_scores]
            #p pairs[0].as_json
            #p pairs[1].as_json
            if !is_awake && previous_state != ActivityUtil::ASLEEP && pairs.length >= sleep_onset_threshold
              #p "sleep onset: first -> #{pairs[0][0].date} with index #{pairs[0][1]}"
              previous_state = ActivityUtil::ASLEEP
              onsets << [previous_state, pairs[0][0].date, pairs[0][1]]
              #p onsets.as_json
            elsif is_awake && previous_state != ActivityUtil::AWAKE && pairs.length >= wake_onset_threshold
              #p "awake onset: first -> #{pairs[0][0].date} with index #{pairs[0][1]}"
              previous_state = ActivityUtil::AWAKE
              onsets << [previous_state, pairs[0][0].date, pairs[0][1]]
            end
          end

          # adjust first onset. The onset index will be reset to 0
          #onsets[0][2] = 0 if !onsets.empty?
          #p onsets.as_json

          # find awakenings
          asleep_time = 0
          awakenings = 0
          awakening_time = 0
          begin_index = -1
          end_index = -1
          first_asleep_onset = onsets.index { |onset| onset[0] == ActivityUtil::ASLEEP }
          #p "From #{first_asleep_onset} to #{onsets.length}"
          unless first_asleep_onset.nil?
            onsets[first_asleep_onset..onsets.length].each_with_index { |onset, i|
              #p "checking onset with index #{i}, onset: #{onset.inspect}"
              if onset[0] == ActivityUtil::ASLEEP
                begin_index = onset[2]
              else
                end_index = onset[2] - 1
              end

              #p 'indexes: ' + begin_index.to_s + '-' + end_index.to_s

              last_index = i == onsets.length - first_asleep_onset - 1

              #p 'last_index: ' + last_index.to_s

              #if begin_index != -1 && ((end_index != -1 && begin_index < end_index) || (last_index && onset[0] == ActivityUtil::ASLEEP))
              #p begin_index != -1
              #p end_index != -1 && begin_index < end_index
              #p onset[0] == ActivityUtil::ASLEEP
              if begin_index != -1 && ((end_index != -1 && begin_index < end_index) || (last_index && onset[0] == ActivityUtil::ASLEEP))
                #p "something at begin_index #{begin_index} and end_index #{end_index}"
                end_index = sleep_scores.length if last_index && onset[0] == ActivityUtil::ASLEEP
                #p "From #{begin_index} to #{end_index}"
                sub_sleep_scores = sleep_scores[begin_index..end_index]
                #p "Sleep += #{sub_sleep_scores.length}"
                asleep_time += sub_sleep_scores.length
                #p asleep_time.to_s + ' indexes: ' + begin_index.to_s + '-' + end_index.to_s
                sub_sleep_scores.chunk { |sleep_score|
                  sleep_score.score == 0
                }.each { |is_awake, ary|
                  if is_awake
                    awakenings += 1
                    awakening_time += ary.length
                    #p [is_awake, ary.to_json]
                  end
                }
              end
            }
          end

          #p awakening_time
          avg_awakening_time = awakenings == 0 ? 0 : awakening_time / awakenings

          #puts "Time elapsed #{Time.now - beginning} seconds"
          #puts "Asleep: #{final_scores.inject(0, :+)} vs #{sleep_scores.inject(0) { |sum, e| sum += e.score }}"

          user_response.awakenings = awakenings
          user_response.avg_awakening_time = avg_awakening_time

          user_response.total_counts = activity_counts.sum(:counts)
          user_response.on_time = activity_counts.count()
          user_response.nonwear_time = activity_counts.count(:conditions => 'charging = true')
          user_response.wear_time = user_response.on_time - user_response.nonwear_time
          user_response.total_time = total_time
          user_response.off_time = total_time - user_response.on_time

          #user_response.total_sleep_time = final_scores.inject(0, :+)
          #user_response.total_sleep_time = sleep_scores.inject(0) { |sum, e| sum += e.score }
          user_response.asleep_time = asleep_time
          #p "#{total_time} -> #{user_response.total_sleep_time} -> #{user_response.off_time}"
          user_response.awake_time = total_time - user_response.asleep_time
          #- user_response.off_time #TODO Revise whether we should consider 'off' as awake or asleep

          user_response.onsets = onsets
        end
      end

      render json: {
          :start_date => start_date.to_formatted_s(:db),
          :end_date => (end_date + 1.minute).to_formatted_s(:db),
          :total_time => total_time,
          :avg_counts => (users.empty? ? 0 : (users.sum(&:total_counts) / users.count())).ceil,
          :avg_asleep_time => (users.empty? ? 0 : (users.sum(&:asleep_time) / users.count())).ceil,
          :avg_awake_time => (users.empty? ? 0 : (users.sum(&:awake_time) / users.count())).ceil,
          :avg_awakenings => (users.empty? ? 0 : (users.sum(&:awakenings) / users.count())).ceil,
          :avg_awakening_time => (users.empty? ? 0 : (users.sum(&:avg_awakening_time) / users.count())).ceil,
          :users => users.map { |user| {
              :username => user.username,
              :total_counts => user.total_counts,
              :asleep_time => user.asleep_time,
              :awake_time => user.awake_time,
              :awakenings => user.awakenings,
              :avg_awakening_time => user.avg_awakening_time,
              :onsets => user.onsets.map { |onset| {
                  :type => onset[0],
                  :date => onset[1].to_formatted_s(:db)
              } },
              :wear_time => user.wear_time,
              :nonwear_time => user.nonwear_time,
              :off_time => user.off_time,
              :on_time => user.on_time,
          } },
          :avg_wear_time => (users.empty? ? 0 : (users.sum(&:wear_time) / users.count())).ceil,
          :avg_nonwear_time => (users.empty? ? 0 : (users.sum(&:nonwear_time) / users.count())).ceil,
          :avg_on_time => (users.empty? ? 0 : (users.sum(&:on_time) / users.count())).ceil,
          :avg_off_time => (users.empty? ? 0 : (users.sum(&:off_time) / users.count())).ceil,
          :icat_status => 200,
          :message => 'OK'
      }, :status => 200
    else
      render json: {:icat_status => validation[1], :message => validation[2]}
    end
  end

  # POST /activity_counts/query_calories.json
  def query_calories
    validation = Util.validate params
    if validation[0]
      json = validation[1]
      start_date = validation[2]
      end_date = validation[3] - 1.minute

      users = Util.validate_users json, Util::RESPONSE_TYPE_ACTIVITY
      calories_algorithm = Util.get_param(json, 'calories_algorithm', ActivityUtil::DEF_CAL_ALGORITHM)
      calories_scale = Util.get_param(json, 'calories_scale', ActivityUtil::DEF_CAL_SCALE)

      total_time = (end_date - start_date + 1.minute).round / 1.minute

      # clear invalid users
      users.reject! { |user| !user.valid }

      # for each user
      users.each do |user_response|
        user = user_response.user

        # if user does not exist
        unless user.nil?
          # query activity counts inside date range
          # NOTE: At this moment, we don't need to order the results. Be careful if code is modified.
          activity_counts = user.activity_counts.where(:date => start_date..end_date)

          user_response.total_counts = activity_counts.sum(:counts)
          user_response.total_steps = activity_counts.sum(:steps)
          user_response.on_time = activity_counts.count()
          user_response.nonwear_time = activity_counts.count(:conditions => 'charging = true')
          user_response.wear_time = user_response.on_time - user_response.nonwear_time
          user_response.total_time = total_time
          user_response.off_time = total_time - user_response.on_time
          user_response.total_calories = ActivityUtil.compute_calories(calories_algorithm, user_response.total_counts, user_response.bmi, calories_scale)
        end
      end

      render json: {
          :start_date => start_date.to_formatted_s(:db),
          :end_date => (end_date + 1.minute).to_formatted_s(:db),
          :total_time => total_time,
          :avg_counts => (users.empty? ? 0 : (users.sum(&:total_counts) / users.count())).ceil,
          :avg_calories => (users.empty? ? 0 : (users.sum(&:total_calories) / users.count())).ceil,
          :avg_steps => (users.empty? ? 0 : (users.sum(&:total_steps) / users.count())).ceil,
          :users => users.map { |user| {
              :username => user.username,
              :bmi => '%0.2f' % user.bmi,
              :total_counts => user.total_counts,
              :total_calories => user.total_calories.ceil,
              :total_steps => user.total_steps,
              :wear_time => user.wear_time,
              :nonwear_time => user.nonwear_time,
              :off_time => user.off_time,
              :on_time => user.on_time,
          } },
          :avg_wear_time => (users.empty? ? 0 : (users.sum(&:wear_time) / users.count())).ceil,
          :avg_nonwear_time => (users.empty? ? 0 : (users.sum(&:nonwear_time) / users.count())).ceil,
          :avg_on_time => (users.empty? ? 0 : (users.sum(&:on_time) / users.count())).ceil,
          :avg_off_time => (users.empty? ? 0 : (users.sum(&:off_time) / users.count())).ceil,
          :icat_status => 200,
          :message => 'OK'
      }, :status => 200
    else
      render json: {:icat_status => validation[1], :message => validation[2]}
    end
  end
end
