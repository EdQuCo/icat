class ActivityUtil
  def self.compute_calories(equation, cpm, bmi)
    case equation
      when 'WILLIAMS98'
        cpm * 0.0000191 * bmi
      else
        -1
    end
  end

  def self.compute_bmi(height, weight)
    if height != -1 && weight != -1
      height_in_m = height / 100
      weight / (height_in_m * height_in_m)
    end
  end

  def self.build_intensities(set)
    intensities = []
    case set
      when 'FREEDSON_ADULT'
        intensities << Intensity.new('sedentary', 0, 99)
        intensities << Intensity.new('light', 100, 759)
        intensities << Intensity.new('lifestyle', 760, 1951)
        intensities << Intensity.new('moderate', 1952, 5724)
        intensities << Intensity.new('vigorous', 5725, 9498)
        intensities << Intensity.new('very vigorous', 9499, 1.0 / 0)
      when 'FREEDSON_ADULT_VM3'
        intensities << Intensity.new('light', 0, 2690)
        intensities << Intensity.new('moderate', 2691, 6166)
        intensities << Intensity.new('vigorous', 6167, 9642)
        intensities << Intensity.new('very vigorous', 9643, 1.0 / 0)
      when 'FREEDSON_CHILDREN'
        intensities << Intensity.new('sedentary', 0, 149)
        intensities << Intensity.new('light', 150, 499)
        intensities << Intensity.new('moderate', 500, 3999)
        intensities << Intensity.new('vigorous', 4000, 7599)
        intensities << Intensity.new('very vigorous', 7600, 1.0 / 0)
      when 'PUYAU_CHILDREN'
        intensities << Intensity.new('sedentary', 0, 799)
        intensities << Intensity.new('light', 800, 3199)
        intensities << Intensity.new('moderate', 3200, 8199)
        intensities << Intensity.new('vigorous', 8200, 1.0 / 0)
      when 'TREUTH_CHILDREN_GIRLS'
        intensities << Intensity.new('sedentary', 0, 99)
        intensities << Intensity.new('light', 100, 2999)
        intensities << Intensity.new('moderate', 3000, 5200)
        intensities << Intensity.new('vigorous', 5201, 1.0 / 0)
      when 'MATTOCKS_CHILDREN'
        intensities << Intensity.new('sedentary', 0, 100)
        intensities << Intensity.new('light', 101, 3580)
        intensities << Intensity.new('moderate', 3581, 6129)
        intensities << Intensity.new('vigorous', 6130, 1.0 / 0)
      when 'EVENSON_CHILDREN'
        intensities << Intensity.new('sedentary', 0, 100)
        intensities << Intensity.new('light', 101, 2295)
        intensities << Intensity.new('moderate', 2296, 4011)
        intensities << Intensity.new('vigorous', 4012, 1.0 / 0)
      when 'PATE_PRESCHOOL'
        intensities << Intensity.new('sedentary', 0, 799)
        intensities << Intensity.new('light', 800, 1679)
        intensities << Intensity.new('moderate', 1680, 3367)
        intensities << Intensity.new('vigorous', 3368, 1.0 / 0)
      when 'TROST_TODDLER'
        intensities << Intensity.new('sedentary', 0, 195)
        intensities << Intensity.new('light', 196, 1672)
        intensities << Intensity.new('moderate_to_vigorous', 1673, 1.0 / 0)
      when 'TROIANO'
        #TODO: Needs revision
        intensities << Intensity.new('sedentary', 0, 99)
        intensities << Intensity.new('light', 100, 2019)
        intensities << Intensity.new('moderate', 2020, 5998)
        intensities << Intensity.new('vigorous', 5999, 1.0 / 0)
      else
        # Freedson Adult simplified
        intensities << Intensity.new('sedentary', 0, 99)
        intensities << Intensity.new('light', 100, 1951)
        intensities << Intensity.new('moderate', 1952, 5724)
        intensities << Intensity.new('hard', 5725, 1.0 / 0)
    end
  end

  def self.initiate_queue()

  end

  def self.compute_epoch_sleep_score(count_array, epoch_index, algorithm)
    case algorithm
      when 'COLE_KRIPKE'
        if true
          puts "#{count_array[epoch_index - 4].counts} - #{count_array[epoch_index - 3].counts} - #{count_array[epoch_index - 2].counts} - #{count_array[epoch_index - 1].counts} - #{count_array[epoch_index].counts} - #{count_array[epoch_index + 1].counts} - #{count_array[epoch_index + 2].counts}"
        0.00001 * (404 * count_array[epoch_index - 4].counts +
            598 * count_array[epoch_index - 3].counts +
            326 * count_array[epoch_index - 2].counts +
            441 * count_array[epoch_index - 1].counts +
            1408 * count_array[epoch_index].counts +
            508 * count_array[epoch_index + 1].counts +
            350 * count_array[epoch_index + 2].counts)
        end
      else
        0
    end
  end
end