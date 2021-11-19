require "random/secure"
require "openssl/hmac"
require "base64"
require "./access_token"

class OAuth2::AccessToken::Mac < OAuth2::AccessToken
  def self.new(pull : NASON::PullParser)
    OAuth2::AccessToken.new(pull).as(self)
  end

  def to_json(json : NASON::Builder) : Nil
    json.object do
      json.field "token_type", "mac"
      json.field "access_token", access_token
      json.field "expires_in", expires_in
      json.field "refresh_token", refresh_token if refresh_token
      json.field "scope", scope if scope
      json.field "mac_algorithm", mac_algorithm
      json.field "mac_key", mac_key
    end
  end
end
