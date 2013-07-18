class StatusCodeUtil
  CODE_ERROR_UNABLE_CREATE = 250

  CODE_ERROR_MISSING_BUNDLE = 401
  CODE_ERROR_JSON_PARSE = 402
  CODE_ERROR_ADDITIONAL_JSON = 403
  CODE_ERROR_API_KEY = 404
  CODE_ERROR_INVALID_USER = 405
  CODE_ERROR_INCOMPATIBLE_TYPE = 406
  CODE_ERROR_INVALID_DATE_RANGE = 407

  CODE_ERROR_CREATING_USER = 501

  def self.get_error values
    error_code = values[0]
    case error_code
      when CODE_ERROR_MISSING_BUNDLE
        error_message = "Missing parameter 'bundle'"
      when CODE_ERROR_JSON_PARSE
        error_message = "JSON Parse error. Details: #{values[1]}"
      when CODE_ERROR_ADDITIONAL_JSON
        error_message = "Must specify additional JSON parameter: [#{values[1]}]"
      when CODE_ERROR_API_KEY
        error_message = 'Wrong API-Key'
      when CODE_ERROR_INVALID_USER
        error_message = "User [#{values[1]}] does not exist"
      when CODE_ERROR_CREATING_USER
        error_message = "Unable to create user [#{values[1]}]: #{values[2]}"
      when CODE_ERROR_UNABLE_CREATE
        error_message = "Unable to create one or more [#{values[1]}] records. Last error: #{values[2]}"
      when CODE_ERROR_INCOMPATIBLE_TYPE
        error_message = "[#{values[1]}] should be of the type [#{values[2]}]"
      when CODE_ERROR_INVALID_DATE_RANGE
        error_message = "[#{values[1]}]->[#{values[2]}] is an invalid date range"
      else
        error_message = 'Unknown error'
    end
    return [error_code, error_message]
  end
end