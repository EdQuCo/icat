class ChangeSurveys < ActiveRecord::Migration
  def up
    change_column :surveys, :question_1, :integer, :null => true, :default => 0, :limit => 2
    change_column :surveys, :question_2, :integer, :null => true, :default => 0, :limit => 2
    change_column :surveys, :question_3, :integer, :null => true, :default => 0, :limit => 2
    change_column :surveys, :question_4, :integer, :null => true, :default => 0, :limit => 2
    change_column :surveys, :question_5, :integer, :null => true, :default => 0, :limit => 2
    add_column :surveys, :s_type, :integer, :default => 0, :limit => 2

    remove_index(:surveys, :name => 'ux_surveys_user_id_date')
    add_index(:surveys, [:user_id, :date, :s_type], :unique => true, :order => {:date => :desc}, :name => 'ux_surveys_user_id_date_type')
  end

  def down
    change_column :surveys, :question_1, :integer, :null => false, :default => 5, :limit => 2
    change_column :surveys, :question_2, :integer, :null => false, :default => 3, :limit => 2
    change_column :surveys, :question_3, :integer, :null => false, :default => 3, :limit => 2
    change_column :surveys, :question_4, :integer, :null => false, :default => 3, :limit => 2
    change_column :surveys, :question_5, :integer, :null => false, :default => 3, :limit => 2
    remove_column :surveys, :s_type

    add_index(:surveys, [:user_id, :date], :unique => true, :order => {:date => :desc}, :name => 'ux_surveys_user_id_date')
  end
end