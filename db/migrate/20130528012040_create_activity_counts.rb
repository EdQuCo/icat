class CreateActivityCounts < ActiveRecord::Migration
  def up
    create_table 'activity_counts' do |t|
      t.integer 'user_id', :null => false
      t.datetime 'date', :null => false
      t.integer 'counts', :null => false, :default => 0, :limit => 2
      t.integer 'epoch', :null => false, :default => 60, :limit => 2
      t.boolean 'charging', :null => false, :default => false
    end

    add_index(:activity_counts, :user_id, :name => 'ix_user_id')
    add_index(:activity_counts, [:user_id, :date], :unique => true, :order => {:timestamp => :desc}, :name => 'ux_user_id_timestamp')
  end

  def down
    drop_table 'activity_counts'
  end
end
