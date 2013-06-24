class StatusCodeUtil
  CODE_ERROR_MISSING_BUNDLE = 401
  CODE_ERROR_JSON_PARSE = 402
  CODE_ERROR_ADDITIONAL_JSON = 403
  CODE_ERROR_API_KEY = 404
  CODE_ERROR_INVALID_USER = 405

  def self.get_error values
    error_code = values[0]
    case error_code
      when CODE_ERROR_MISSING_BUNDLE
        error_message = "Missing parameter 'bundle'"
      when CODE_ERROR_JSON_PARSE
        error_message = "JSON Parse error. Details: #{values[1]}"
      when CODE_ERROR_ADDITIONAL_JSON
        error_message = "Must specify additional JSON parameter: #{values[1]}"
      when CODE_ERROR_API_KEY
        error_message = 'Wrong API-Key'
      when CODE_ERROR_INVALID_USER
        error_message = "User '#{values[1]}' does not exist"
      else
        error_message = 'Unknown error'
    end
    return [error_code, error_message]
  end
end