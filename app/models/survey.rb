class Survey < ActiveRecord::Base
  belongs_to :user

  attr_accessible :date, :question_1, :question_2, :question_3, :question_4, :question_5, :s_type
end
