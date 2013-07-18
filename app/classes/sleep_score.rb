class SleepScore
  attr_accessor :date, :counts, :valid, :score

  def initialize(date, counts, valid)
    @date = date
    @counts = counts
    @valid = valid
  end

  def is_valid?
    @valid
  end
end