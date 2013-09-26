class ActivityCount < ActiveRecord::Base
  belongs_to :user

  attr_accessible :date, :counts, :steps, :epoch, :charging

  #scope :filter_by_date, lambda { |dates, times|
  #  clauses = []
  #  args = []
  #  tn = times[0]
  #  tm = times[1]
  #  dates.split(',').each do |date|
  #    m, d, y = date.split '/'
  #    b = "#{d}-#{m}-#{y} 00:00:00"
  #    e = "#{d}-#{m}-#{y} 23:59:59"
  #    clauses << '((date >= ? AND date <= ?) AND (CAST(date AS TIME) >= ? OR CAST(date AS TIME) <= ?))'
  #    args.push b, e, tn, tm
  #  end
  #  where clauses.join(' OR '), *args
  #}
  #
  #scope :filter_by_time, lambda { |times|
  #  args = []
  #  %w(21:00:00 09:00:00).each do |time|
  #    h, m, s = time.split(':')
  #    #h = (h.to_i + 12).to_s if time[:meridian] == 'pm'
  #    h = '0' + h if h.length == 1
  #    s = '00' if s.nil?
  #    args.push "#{h}:#{m}:#{s}"
  #  end
  #
  #  puts args
  #
  #  where('CAST(date AS TIME) >= ? OR
  #       CAST(date AS TIME) <= ?', *args)
  #}
end
