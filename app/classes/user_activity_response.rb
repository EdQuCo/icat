class UserActivityResponse < UserResponse
  attr_accessor :bmi, :total_counts, :total_calories, :intensities,
                :wear_time, :nonwear_time, :on_time, :off_time

  def initialize(username, bmi)
    super username
    @bmi = bmi
  end
end