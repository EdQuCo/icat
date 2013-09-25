class UserActivityResponse < UserResponse
  attr_accessor :bmi, :total_counts, :total_calories, :total_steps, :intensities,
                :wear_time, :nonwear_time, :on_time, :off_time

  def initialize(username, bmi)
    super username
    @bmi = bmi
  end
end