require "./access_token"

class OAuth2::AccessToken::Bearer < OAuth2::AccessToken
  def self.new(pull : JSON::PullParser | NASON::PullParser)
    OAuth2::AccessToken.new(pull).as(self)
  end

  def initialize(access_token, expires_in, refresh_token = nil, scope = nil, extra = nil)
    super(access_token, expires_in, refresh_token, scope, extra)
  end

  def token_type : String
    "Bearer"
  end

  def authenticate(request : HTTP::Request, tls)
    request.headers["Authorization"] = "Bearer #{access_token}"
  end

  def to_json(json : JSON::Builder | NASON::Builder) : Nil
    json.object do
      json.field "token_type", "bearer"
      json.field "access_token", access_token
      json.field "expires_in", expires_in
      json.field "refresh_token", refresh_token if refresh_token
      json.field "scope", scope if scope
    end
  end

  def_equals_and_hash access_token, expires_in, refresh_token, scope
end
