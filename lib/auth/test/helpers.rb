require 'webmock/minitest'

module Auth
  module Test
    module Helpers
      JWS_ALGORITHM = 'RS256'

      # a factory for JWT id_tokens
      private def id_token_for(subject)
        JSON::JWT.new(
          iss: Auth.config.issuer,
          aud: Auth.config.audience,
          sub: subject,
          iat: 10.seconds.ago,
          exp: 1.hour.from_now
        ).sign(jws_keypair, JWS_ALGORITHM).to_s
      end

      # a temporary RSA key for our test suite.
      #
      # generates the smallest (fastest) key possible for RS256
      private def jws_keypair
        @keypair ||= OpenSSL::PKey::RSA.new(512)
      end

      # stubs the endpoints necessary to validate a signed JWT
      private def stub_auth_server
        stub_request(:get, "#{Auth.config.issuer}#{Auth.config.configuration_path}").to_return(
          status: 200,
          body: {'jwks_uri' => "#{Auth.config.issuer}/jwks"}.to_json
        )
        stub_request(:get, "#{Auth.config.issuer}/jwks").to_return(
          status: 200,
          body: {
            keys: [
              jws_keypair.public_key.to_jwk.slice(:kty, :kid, :e, :n).merge(
                use: 'sig',
                alg: JWS_ALGORITHM
              )
            ]
          }.to_json
        )
      end

    end
  end
end
