class SurveyResponse
  attr_accessor :date, :score, :taken

  def initialize(name, min, max)
    @name = name
    @min = min
    @max = max
    @counts = 0
    @time = 0
    @calories = 0
    @bouts = 0
  end
end