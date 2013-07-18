class UserSleepResponse < UserResponse
  attr_accessor :total_counts, :wear_time, :nonwear_time, :on_time, :off_time,
                :asleep_time, :awake_time, :awakenings, :avg_awakening_time, :onsets
end