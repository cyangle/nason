class OAuth::AccessToken
  def self.new(pull : NASON::PullParser)
    token = nil
    secret = nil
    extra = nil

    pull.read_object do |key|
      case key
      when "oauth_token"
        token = pull.read_string
      when "oauth_token_secret"
        secret = pull.read_string
      else
        if pull.kind.string?
          extra ||= {} of String => String
          extra[key] = pull.read_string
        else
          pull.skip
        end
      end
    end

    new token.not_nil!, secret.not_nil!, extra
  end

  def to_json(json : NASON::Builder)
    json.object do
      json.field "oauth_token", @token
      json.field "oauth_token_secret", @secret
      @extra.try &.each do |key, value|
        json.field key, value
      end
    end
  end
end
