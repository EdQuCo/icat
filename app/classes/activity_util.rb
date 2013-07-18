class ActivityUtil
  # Sleep Scoring
  SS_ALGORITHM_FASTEST = 'FASTEST'
  SS_ALGORITHM_COLE_KRIPKE = 'COLE_KRIPKE'
  SS_ALGORITHM_COLE_KRIPKE_NO_RS = 'COLE_KRIPKE_NO_RS'

  DEF_SS_ALGORITHM = SS_ALGORITHM_COLE_KRIPKE

  DEF_PARAM_SLEEP_THRESHOLD = 5
  DEF_PARAM_SCALE = 0.001
  DEF_SLEEP_ONSET_THRESHOLD = 30 # minutes
  DEF_AWAKE_ONSET_THRESHOLD = 30 # minutes

  AWAKE = 0
  ASLEEP = 1

  # Calories
  CAL_ALGORITHM_WILLIAMS_98 = 'WILLIAMS_98'
  CAL_ALGORITHM_FREEDSON_VM3 = 'FREEDSON_VM3'
  CAL_ALGORITHM_FREEDSON_CMB = 'FREEDSON_CMB'

  DEF_CAL_ALGORITHM = CAL_ALGORITHM_WILLIAMS_98
  DEF_CAL_SCALE = 10

  # Activity
  CPS_FREEDSON_ADULT = 'FREEDSON_ADULT'
  CPS_FREEDSON_ADULT_SIMPLIFIED = 'FREEDSON_ADULT_SIMPLIFIED'
  CPS_FREEDSON_ADULT_VM3 = 'FREEDSON_ADULT_VM3'
  CPS_FREEDSON_CHILDREN = 'FREEDSON_CHILDREN'
  CPS_PUYAU_CHILDREN = 'PUYAU_CHILDREN'
  CPS_TREUTH_CHILDREN_GIRLS = 'TREUTH_CHILDREN_GIRLS'
  CPS_MATTOCKS_CHILDREN = 'MATTOCKS_CHILDREN'
  CPS_EVENSON_CHILDREN = 'EVENSON_CHILDREN'
  CPS_PATE_PRESCHOOL = 'PATE_PRESCHOOL'
  CPS_TROST_TODDLER = 'TROST_TODDLER'
  CPS_TROIANO = 'TROIANO'

  DEF_CUT_POINTS_SET = CPS_FREEDSON_ADULT_SIMPLIFIED

  DEF_BOUT_ALLOWANCE = 2
  DEF_BOUT_SIZE = 10

  #@@intensity_index = -1

  def self.compute_calories(equation, cpm, bmi,scale)
    case equation
      when CAL_ALGORITHM_WILLIAMS_98
        scale * cpm * 0.0000191 * bmi
      when CAL_ALGORITHM_FREEDSON_VM3
        scale * 0.001064 * cpm + 0.087512 * bmi - 5.500229
      when CAL_ALGORITHM_FREEDSON_CMB
        scale * 0.00094 * cpm + (0.1346 * bmi - 7.37418)
        #0.001064 * cpm + 0.087512 * bmi - 5.500229
      else
        scale * cpm * 0.0000191 * bmi
    end
  end

  def self.compute_bmi(height, weight)
    if height != -1 && weight != -1
      height_in_m = height / 100.0
      weight / (height_in_m * height_in_m)
    else
      25
    end
  end

  def self.build_intensities(set)
    intensities = []
    case set
      when CPS_FREEDSON_ADULT_SIMPLIFIED
        intensities << Intensity.new(0, 'sedentary', 0, 99)
        intensities << Intensity.new(1, 'light', 100, 1951)
        intensities << Intensity.new(2, 'moderate', 1952, 5724)
        intensities << Intensity.new(3, 'hard', 5725, 999999)
      when CPS_FREEDSON_ADULT
        intensities << Intensity.new(0, 'sedentary', 0, 99)
        intensities << Intensity.new(1, 'light', 100, 759)
        intensities << Intensity.new(2, 'lifestyle', 760, 1951)
        intensities << Intensity.new(3, 'moderate', 1952, 5724)
        intensities << Intensity.new(4, 'vigorous', 5725, 9498)
        intensities << Intensity.new(5, 'very vigorous', 9499, 999999)
      when CPS_FREEDSON_ADULT_VM3
        intensities << Intensity.new(0, 'light', 0, 2690)
        intensities << Intensity.new(1, 'moderate', 2691, 6166)
        intensities << Intensity.new(2, 'vigorous', 6167, 9642)
        intensities << Intensity.new(3, 'very vigorous', 9643, 999999)
      when CPS_FREEDSON_CHILDREN
        intensities << Intensity.new(0, 'sedentary', 0, 149)
        intensities << Intensity.new(1, 'light', 150, 499)
        intensities << Intensity.new(2, 'moderate', 500, 3999)
        intensities << Intensity.new(3, 'vigorous', 4000, 7599)
        intensities << Intensity.new(4, 'very vigorous', 7600, 999999)
      when CPS_PUYAU_CHILDREN
        intensities << Intensity.new(0, 'sedentary', 0, 799)
        intensities << Intensity.new(1, 'light', 800, 3199)
        intensities << Intensity.new(2, 'moderate', 3200, 8199)
        intensities << Intensity.new(3, 'vigorous', 8200, 999999)
      when CPS_TREUTH_CHILDREN_GIRLS
        intensities << Intensity.new(0, 'sedentary', 0, 99)
        intensities << Intensity.new(1, 'light', 100, 2999)
        intensities << Intensity.new(2, 'moderate', 3000, 5200)
        intensities << Intensity.new(3, 'vigorous', 5201, 999999)
      when CPS_MATTOCKS_CHILDREN
        intensities << Intensity.new(0, 'sedentary', 0, 100)
        intensities << Intensity.new(1, 'light', 101, 3580)
        intensities << Intensity.new(2, 'moderate', 3581, 6129)
        intensities << Intensity.new(3, 'vigorous', 6130, 999999)
      when CPS_EVENSON_CHILDREN
        intensities << Intensity.new(0, 'sedentary', 0, 100)
        intensities << Intensity.new(1, 'light', 101, 2295)
        intensities << Intensity.new(2, 'moderate', 2296, 4011)
        intensities << Intensity.new(3, 'vigorous', 4012, 999999)
      when CPS_PATE_PRESCHOOL
        intensities << Intensity.new(0, 'sedentary', 0, 799)
        intensities << Intensity.new(1, 'light', 800, 1679)
        intensities << Intensity.new(2, 'moderate', 1680, 3367)
        intensities << Intensity.new(3, 'vigorous', 3368, 999999)
      when CPS_TROST_TODDLER
        intensities << Intensity.new(0, 'sedentary', 0, 195)
        intensities << Intensity.new(1, 'light', 196, 1672)
        intensities << Intensity.new(2, 'moderate_to_vigorous', 1673, 999999)
      when CPS_TROIANO
        #TODO: Needs revision
        intensities << Intensity.new(0, 'sedentary', 0, 99)
        intensities << Intensity.new(1, 'light', 100, 2019)
        intensities << Intensity.new(2, 'moderate', 2020, 5998)
        intensities << Intensity.new(3, 'vigorous', 5999, 999999)
      else
        # Freedson Adult simplified
        intensities << Intensity.new(0, 'sedentary', 0, 99)
        intensities << Intensity.new(1, 'light', 100, 1951)
        intensities << Intensity.new(2, 'moderate', 1952, 5724)
        intensities << Intensity.new(3, 'hard', 5725, 999999)
    end
  end

  def self.compute_epoch_sleep_score(epoch_queue, main_index, algorithm, params)
    # if some value in the queue is invalid (off|nonwear) score as wake
    if epoch_queue.find_all{|item| !item.valid}.size > 0
      return AWAKE
    end

    case algorithm
      when SS_ALGORITHM_COLE_KRIPKE || SS_ALGORITHM_COLE_KRIPKE_NO_RS
        # D = 0.00001(404 * A_(-4) + 598 * A_(-3) + 326 * A_(-2) + 441 * A_(-1) + 1408 * A_0 + 508 * A_(+1) + 350 * A_(+2))
        #puts "#{count_array[epoch_index - 4].counts} - #{count_array[epoch_index - 3].counts} - #{count_array[epoch_index - 2].counts} - #{count_array[epoch_index - 1].counts} - #{count_array[epoch_index].counts} - #{count_array[epoch_index + 1].counts} - #{count_array[epoch_index + 2].counts}"
        params[0] * (404 * epoch_queue[main_index - 4].counts +
            598 * epoch_queue[main_index - 3].counts +
            326 * epoch_queue[main_index - 2].counts +
            441 * epoch_queue[main_index - 1].counts +
            1408 * epoch_queue[main_index].counts +
            508 * epoch_queue[main_index + 1].counts +
            350 * epoch_queue[main_index + 2].counts) >= 1 ? AWAKE : ASLEEP
      when SS_ALGORITHM_FASTEST
        epoch_queue[main_index].counts > params[0] ? AWAKE : ASLEEP
      else
        AWAKE
    end
  end

  def self.rescore(sleep_scores, m, sur_min)
    if sleep_scores.length > sur_min
      # after at least sur_min minutes scored as wake,
      # the next m minutes scored as sleep are rescored as wake
      wake = 0
      iter = sleep_scores.to_enum
      while true
        begin
          sleep_score = iter.next
        rescue StopIteration
          break
        end

        if sleep_score.score == ASLEEP
          if wake >= sur_min
            sleep_score.score = AWAKE
            (m - 1).times {
              begin
                sleep_score = iter.next
              rescue StopIteration
                break
              end
              sleep_score.score = AWAKE
            }
          end
          wake = 0
        else
          wake += 1
        end
      end
    end
  end

  def self.rescore_with_neighbors(sleep_scores, m, sur_min)
    if sleep_scores.length > sur_min * 2
      # m minutes or less scored as sleep surrounded by at least sur_min minutes
      # (before and after) scored as wake are rescored as wake
      wake_before = 0
      wake_after = 0
      wake_between = 0
      between_scores = []
      before = true
      sleep_scores.each do |sleep_score|
        if sleep_score.score == AWAKE
          if before
            wake_before += 1
          else
            wake_after += 1
            # rescore?
            if wake_before >= sur_min && wake_after >= sur_min
              between_scores.map! { |s| s.score = AWAKE }
              between_scores = []
              wake_between = 0
              wake_before = wake_after
              wake_after = 0
              before = true
            end
          end
        else
          if before
            if wake_before >= sur_min
              before = false
              between_scores << sleep_score
            else
              between_scores = []
              wake_before = 0
            end
          else
            # rescore?
            if wake_before >= sur_min && wake_after >= sur_min
              between_scores.map! { |s| s.score = AWAKE }
              between_scores = []
              wake_between = 0
              wake_before = wake_after
              wake_after = 0
              before = true
            else
              between_scores << sleep_score
              wake_between += wake_after
              # sleep queue overload?
              if (between_scores.length + wake_between) > m
                between_scores = []
                wake_between = 0
                wake_before = wake_after
                wake_after = 0
                before = true
              end
            end
          end
        end
      end
    end

    # The next snippet is a lot prettier but slower (~x2) :s
    ########################################
    #sleep_scores_chunked = sleep_scores.chunk { |s| s.score == ActivityUtil::ASLEEP }.to_a
    #sleep_scores_chunked.each_with_index { |chunk, i|
    #  if chunk[0] && (i - 1 >= 0) && (i + 1 < sleep_scores_chunked.length)
    #    #p 'yes'
    #    if chunk[1].length <= 6 && sleep_scores_chunked[i - 1][1].length >= 10 && sleep_scores_chunked[i + 1][1].length >= 10
    #      #p "#{i} -> #{chunk[1].length} -> rescored: #{chunk[1].length}"
    #      #chunk[1].map{|s| s.score = ActivityUtil::AWAKE}
    #      chunked += chunk[1].length
    #    end
    #  end
    #}
    ########################################
  end

  def self.get_bouts(activity_counts, size, allowance, intensities)
    intensities.each do |intensity|
      intensity.bouts = 0
    end
    if activity_counts.length >= size
      # 1 bout = 'size' consecutive minutes (with an allowance of 'allowance' minutes)
      # performing physical activity with a level between min and max counts
      bout_queue = Array.new(size, -1)
      activity_counts.each do |count|
        bout_queue.shift
        bout_queue << get_intensity(count.counts, intensities)
        qr = analyze_queue(bout_queue, size - allowance)
        if qr[0]
          #p 'resetting queue'
          intensities[qr[1]].bouts += 1
          #p "intensity bouts = #{intensities[qr[1]].bouts}"
          bout_queue = Array.new(size, -1)
        end
      end
    end
  end

  def self.analyze_queue(queue, min)
    #p '->'
    #p queue.as_json
    sort_queue = queue.inject(Hash.new(0)) { |total, e| total[e] += 1; total }.sort_by { |key, value| value }.reverse
    #p sort_queue
    if sort_queue[0][0] != -1 && sort_queue[0][1] >= min
      #p "true -> #{sort_queue[0][0]}"
      [true, sort_queue[0][0]]
    else
      [false]
    end
  end

  def self.get_intensity(counts, intensities)
    intensities.each do |intensity|
      if counts.between?(intensity.min, intensity.max)
        return intensity.index
      end
    end
    intensities[0].index
  end

  def self.get_ss_algorithm_params(algorithm)
    case algorithm
      when SS_ALGORITHM_COLE_KRIPKE || SS_ALGORITHM_COLE_KRIPKE_NO_RS
        [DEF_PARAM_SCALE]
      when SS_ALGORITHM_FASTEST
        [DEF_PARAM_SLEEP_THRESHOLD]
      else
        [DEF_PARAM_SCALE]
    end
  end
end