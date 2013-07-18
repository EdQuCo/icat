class UserSurveyResponse < UserResponse
  attr_accessor :surveys, :avg_score, :surveys_taken, :surveys_ignored

  #def initialize(username)
  #  super username
  #  @avg_score = 0
  #  @surveys_taken = 0
  #  @surveys_ignored = 0
  #end
end