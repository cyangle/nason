abstract class OAuth2::AccessToken
  def self.new(pull : NASON::PullParser)
    token_type = nil
    access_token = nil
    expires_in = nil
    refresh_token = nil
    scope = nil
    mac_algorithm = nil
    mac_key = nil
    extra = nil

    pull.read_object do |key|
      case key
      when "token_type"    then token_type = pull.read_string
      when "access_token"  then access_token = pull.read_string
      when "expires_in"    then expires_in = pull.read_int
      when "refresh_token" then refresh_token = pull.read_string_or_null
      when "scope"         then scope = pull.read_string_or_null
      when "mac_algorithm" then mac_algorithm = pull.read_string
      when "mac_key"       then mac_key = pull.read_string
      else
        extra ||= {} of String => String
        extra[key] = pull.read_raw
      end
    end

    access_token = access_token.not_nil!

    token_type ||= "bearer"

    case token_type.downcase
    when "bearer"
      Bearer.new(access_token, expires_in, refresh_token, scope, extra)
    when "mac"
      Mac.new(access_token, expires_in, mac_algorithm.not_nil!, mac_key.not_nil!, refresh_token, scope, Time.utc.to_unix, extra)
    else
      raise "Unknown token_type in access token json: #{token_type}"
    end
  end
end
