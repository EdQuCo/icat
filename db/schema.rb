# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130926001058) do

  create_table "activity_counts", :force => true do |t|
    t.integer  "user_id",                                  :null => false
    t.datetime "date",                                     :null => false
    t.integer  "counts",   :limit => 2, :default => 0
    t.integer  "epoch",    :limit => 2, :default => 60
    t.boolean  "charging",              :default => false
    t.integer  "steps",    :limit => 2, :default => 0
  end

  add_index "activity_counts", ["user_id", "date"], :name => "ux_user_id_timestamp", :unique => true
  add_index "activity_counts", ["user_id"], :name => "ix_user_id"

  create_table "surveys", :force => true do |t|
    t.integer  "user_id",                                :null => false
    t.datetime "date",                                   :null => false
    t.integer  "question_1", :limit => 2, :default => 0
    t.integer  "question_2", :limit => 2, :default => 0
    t.integer  "question_3", :limit => 2, :default => 0
    t.integer  "question_4", :limit => 2, :default => 0
    t.integer  "question_5", :limit => 2, :default => 0
    t.integer  "s_type",     :limit => 2, :default => 0
  end

  add_index "surveys", ["user_id", "date", "s_type"], :name => "ux_surveys_user_id_date_type", :unique => true, :order => {"date"=>:desc}
  add_index "surveys", ["user_id"], :name => "ix_surveys_user_id"

  create_table "users", :force => true do |t|
    t.string "username", :limit => 30, :null => false
  end

  add_index "users", ["username"], :name => "ix_name"

end
