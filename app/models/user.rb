class User < ActiveRecord::Base
  has_many :activity_counts, :dependent => :delete_all

  attr_accessible :username
end
