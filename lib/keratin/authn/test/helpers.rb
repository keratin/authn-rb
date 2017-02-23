module Keratin::AuthN
  module Test
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
        ).sign(jws_keypair.to_jwk, JWS_ALGORITHM).to_s
      end

      # a temporary RSA key for the test suite.
      #
      # generates the smallest (fastest) key possible for RS256
      private def jws_keypair
        @keypair ||= OpenSSL::PKey::RSA.new(512)
      end
    end
  end
end
