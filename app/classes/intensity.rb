class Intensity
  attr_accessor :name, :min, :max, :time, :calories, :counts, :bouts

  def initialize(name, min, max)
    @name = name
    @min = min
    @max = max
    @counts = 0
    @time = 0
    @calories = 0
    @bouts = 0
  end

  def add_counts(counts)
    @counts += counts
  end

  def add_time(time)
    @time += time
  end

  def add_calories(calories)
    @calories += calories
  end

  def add_bouts
    @bouts += 1
  end

  def in_range?(counts)
    counts.between?(@min, @max)
  end
end