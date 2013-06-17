class User < ActiveRecord::Base
  has_many :activity_counts, :dependent => :delete_all
  has_many :surveys, :dependent => :delete_all

  attr_accessible :username
end
