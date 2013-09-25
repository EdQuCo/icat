class Intensity
  attr_accessor :name, :min, :max, :time, :calories, :counts, :steps, :bouts, :in_bout, :index

  def initialize(index, name, min, max)
    @index = index
    @name = name
    @min = min
    @max = max
    @counts = 0
    @steps = 0
    @time = 0
    @calories = 0
    @bouts = -1
  end
end