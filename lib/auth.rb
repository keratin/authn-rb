require_relative 'auth/version'
require_relative 'auth/id_token_verifier'
require_relative 'auth/issuer'

require 'json/jwt'
module Auth
  CONFIG = {
    issuer: "https://issuer.tech",
    configuration_path: "/configuration",
    audience: "audience.tech",
  }

  class << self
    # safely fetches a subject from the id token after checking relevant claims and
    # verifying the signature.
    #
    # this may involve HTTP requests to fetch the issuer's configuration and JWKs.
    def subject_from(id_token)
      verifier = IDTokenVerifier.new(id_token)
      verifier.subject if verifier.verified?
    end

    def issuer_signing_key(iss)
      Issuer.new(iss).signing_key
    end
  end

end
