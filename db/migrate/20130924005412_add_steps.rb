class AddSteps < ActiveRecord::Migration
  def up
    add_column :activity_counts, :steps, :integer, :default => 0, :limit => 2
  end

  def down
    remove_column :activity_counts, :steps
  end
end
