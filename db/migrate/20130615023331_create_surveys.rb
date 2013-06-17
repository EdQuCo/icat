class CreateSurveys < ActiveRecord::Migration
  def up
    create_table 'surveys' do |t|
      t.integer 'user_id', :null => false
      t.datetime 'date', :null => false
      t.integer 'question_1', :null => false, :default => 5, :limit => 2
      t.integer 'question_2', :null => false, :default => 3, :limit => 2
      t.integer 'question_3', :null => false, :default => 3, :limit => 2
      t.integer 'question_4', :null => false, :default => 3, :limit => 2
      t.integer 'question_5', :null => false, :default => 3, :limit => 2
    end

    add_index(:surveys, :user_id, :name => 'ix_surveys_user_id')
    add_index(:surveys, [:user_id, :date], :unique => true, :order => {:date => :desc}, :name => 'ux_surveys_user_id_date')
  end

  def down
    drop_table 'surveys'
  end
end
