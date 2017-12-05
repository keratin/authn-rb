module Keratin::AuthN::Test
  module Helpers
    JWS_ALGORITHM = 'RS256'

    # a factory for JWT id_tokens
    private def id_token_for(subject)
      JSON::JWT.new(
        iss: Keratin::AuthN.config.issuer,
        aud: Keratin::AuthN.config.audience,
        sub: subject,
        iat: 10.seconds.ago,
        exp: 1.hour.from_now
      ).sign(Keratin::AuthN.keychain.key, JWS_ALGORITHM).to_s
    end
  end
end
