class Util
  def self.validate(params)

    unless params.has_key?(:bundle)
      return [false].concat StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_MISSING_BUNDLE])
    end

    begin
      json = JSON.parse(params[:bundle])
    rescue => ex
      return [false].concat StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_JSON_PARSE, ex])
    end

    # validate API-key
    api_key = json['api_key']
    if api_key.blank?
      return [false].concat StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_ADDITIONAL_JSON, 'api_key'])
    else
      if api_key != 'iCAT-2013-1234567890'
        return [false].concat StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_API_KEY])
      end
    end

    # validate username
    username = json['username']
    if username.blank?
      return [false].concat StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_ADDITIONAL_JSON, 'username'])
    end

    user = User.find_by_username(username)
    # if user does not exist
    if user.nil?
      return [false].concat StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_INVALID_USER, username])
    else
      start_date = json['start_date']
      if start_date.blank?
        return [false].concat StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_ADDITIONAL_JSON, 'start_date'])
      else
        begin
          start_date = DateTime.parse(start_date).to_time
        rescue => ex
          return [false].concat StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_JSON_PARSE, ex])
        end
      end

      end_date = json['end_date']
      if end_date.blank?
        return [false].concat StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_ADDITIONAL_JSON, 'end_date'])
      else
        begin
          end_date = DateTime.parse(end_date).to_time
        rescue => ex
          return [false].concat StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_JSON_PARSE, ex])
        end
      end

    end

    return [true, json, user, start_date, end_date]
  end

=begin
  def self.compute_sleep_score(activity_counts, start_date, end_date)
    activity_counts.each do |activity_count|
      puts activity_count.date
      if activity_count.date < start_date
        puts 'SMALLER THAN START'
      else
        puts 'BIGGER THAN START'
        if activity_count.date < end_date
          puts 'SMALLER THAN END'
        else
          puts 'BIGGER THAN END'
        end
      end
    end
  end
=end

=begin
  def self.compute_calories(equation, cpm, bmi)
    case equation
      when 'WILLIAMS98'
        cpm * 0.0000191 * bmi
      else
        -1
    end
  end
=end
end