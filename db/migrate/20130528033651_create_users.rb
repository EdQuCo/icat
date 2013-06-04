class CreateUsers < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.string 'username', :null => false, :limit => 30, :unique => true
    end

    add_index :users, :username, :name => 'ix_name'
  end

  def down
    drop_table :users
  end
end
