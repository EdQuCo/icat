class DateTime
  def as_json(options = nil)
    strftime('%Y-%m-%d %H:%M:%S')
  end
end