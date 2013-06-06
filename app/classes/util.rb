class Util
=begin
  def self.compute_sleep_score(activity_counts, start_date, end_date)
    activity_counts.each do |activity_count|
      puts activity_count.date
      if activity_count.date < start_date
        puts 'SMALLER THAN START'
      else
        puts 'BIGGER THAN START'
        if activity_count.date < end_date
          puts 'SMALLER THAN END'
        else
          puts 'BIGGER THAN END'
        end
      end
    end
  end
=end

=begin
  def self.compute_calories(equation, cpm, bmi)
    case equation
      when 'WILLIAMS98'
        cpm * 0.0000191 * bmi
      else
        -1
    end
  end
=end
end