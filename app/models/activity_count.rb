class ActivityCount < ActiveRecord::Base
  belongs_to :user

  attr_accessible :date, :counts, :epoch, :charging
end
