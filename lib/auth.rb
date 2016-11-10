require_relative 'auth/version'
require_relative 'auth/engine' if defined?(Rails)
require_relative 'auth/id_token_verifier'
require_relative 'auth/issuer'

require 'json/jwt'
module Auth
  class Config
    # the domain (host) of the main application.
    # e.g. "audience.tech"
    attr_accessor :audience

    # the path where we can fetch configuration from our issuer.
    # e.g. "/configuration"
    attr_accessor :configuration_path

    # the base url of the service handling authentication
    # e.g. "https://issuer.tech"
    attr_accessor :issuer
  end

  def self.config
    @config ||= Config.new.tap do |config|
      config.configuration_path = '/configuration'
    end
  end

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
