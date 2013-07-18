class UserResponse
  attr_accessor :user, :username, :valid,
                :total_time

  def initialize(username)
    @username = username
    @user = User.find_by_username(username)
    if @user.nil?
      @valid = false
    else
      @valid = true
    end
  end
end