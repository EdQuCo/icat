class Util
  RESPONSE_TYPE_ACTIVITY = 1
  RESPONSE_TYPE_SLEEP = 2
  RESPONSE_TYPE_SURVEY = 3

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
      if api_key != 'iCAT-2013-1234567890' && api_key != 'iCAT-ti2013'
        return [false].concat StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_API_KEY])
      end
    end

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

    if end_date < start_date
      return [false].concat StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_INVALID_DATE_RANGE, start_date.to_formatted_s(:db), end_date.to_formatted_s(:db)])
    end

    users = json['users']
    if users.blank?
      return [false].concat StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_ADDITIONAL_JSON, 'users'])
    else
      unless users.kind_of?(Array)
        return [false].concat StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_INCOMPATIBLE_TYPE, 'users', 'Array'])
      end
    end

    return [true, json, start_date, end_date]
  end

  def self.validate_creation(params)

    # validate bundle
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

    # validate user
    user = User.find_by_username(username)
    # create user if not existent
    if user.nil?
      user = User.new(:username => username)
      begin
        user.save
      rescue => ex
        return [false].concat StatusCodeUtil.get_error([StatusCodeUtil::CODE_ERROR_CREATING_USER, username, ex])
      end
    end

    return [true, json, user]
  end

  def self.validate_users(json, response_type)
    users = []
    json_users = json.fetch('users')
    json_users.each do |json_user|
      username = get_param(json_user, 'username', 'icat_invalid_user')
      case response_type
        when RESPONSE_TYPE_ACTIVITY
          height = get_param(json_user, 'height', 170)
          weight = get_param(json_user, 'weight', 70)
          bmi = ActivityUtil.compute_bmi(height, weight)
          users << UserActivityResponse.new(username, bmi)
        when RESPONSE_TYPE_SLEEP
          users << UserSleepResponse.new(username)
        when RESPONSE_TYPE_SURVEY
          users << UserSurveyResponse.new(username)
        else
          puts 'Unknown response type'
      end

    end

    users
  end

  def self.validate_survey_users(json)
    users = []
    json_users = json.fetch('users')
    json_users.each do |json_user|
      username = get_param(json_user, 'username', 'icat_invalid_user')
      users << UserSurveyResponse.new(username)
    end

    users
  end

  def self.get_param(json, param, default)
    value = json[param]
    if value.blank?
      value = default
    end

    value
  end

  def self.get_array_param(json, param, default)
    value = json[param]
    if value.blank? || !value.kind_of?(Array)
      value = default
    end

    value
  end

  def self.round(value)
    return (value + 0.5).floor if value > 0.0
    return (value - 0.5).ceil if value < 0.0
    return 0
  end

  #TODO replace each
  def self.deep_copy(intensities)
    copy = []
    intensities.each { |intensity|
      copy << intensity.clone
    }
    copy
  end
end