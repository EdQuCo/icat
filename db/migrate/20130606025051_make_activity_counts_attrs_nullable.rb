class MakeActivityCountsAttrsNullable < ActiveRecord::Migration
  def up
    change_column :activity_counts, :counts, :integer, :null => true, :default => 0, :limit => 2
    change_column :activity_counts, :epoch, :integer, :null => true, :default => 60, :limit => 2
    change_column :activity_counts, :charging, :boolean, :null => true, :default => false
  end

  def down
    change_column :activity_counts, :counts, :integer, :null => false, :limit => 2
    change_column :activity_counts, :epoch, :integer, :null => false, :limit => 2
    change_column :activity_counts, :charging, :boolean, :null => false
  end
end
