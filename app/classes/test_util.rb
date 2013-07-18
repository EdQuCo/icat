require 'active_record'
require 'pg'

class TestUtil < ActiveRecord::Base
  def self.test_db
    sd = DateTime.parse('2015-01-02 00:00:00')
    ed = DateTime.parse('2015-01-03 00:00:00')

    inserts = []
    (sd.to_i .. ed.to_i).step(1.minute) do |date|
      #puts Time.at(date).utc
      inserts.push "(11, '#{Time.at(date).utc}', 100, 60, '0')"
    end

    #(sd..ed).step(1.minute) do |date|
    #  inserts.push "(11, '#{date}', 100, 60, '0')"
    #end

    sql = "INSERT INTO activity_counts (user_id, date, counts, epoch, charging) VALUES #{inserts.join(', ')}"
    begin
      ActiveRecord::Base.connection.execute(sql)
    rescue => ex
      puts "Error: #{ex}"
    end

  end

end