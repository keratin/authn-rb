require_relative 'auth/version'
require_relative 'auth/engine' if defined?(Rails)
require_relative 'auth/id_token_verifier'
require_relative 'auth/issuer'

require 'lru_redux'
require 'json/jwt'

module Auth
  class Config
    # the domain (host) of the main application.
    # e.g. "audience.tech"
    attr_accessor :audience

    # the base url of the service handling authentication
    # e.g. "https://issuer.tech"
    attr_accessor :issuer

    # the path where we can fetch configuration from our issuer.
    #
    # default: "/configuration"
    attr_accessor :configuration_path

    # how long (in seconds) to keep keys in the keychain before refreshing.
    # default: 3600
    attr_accessor :keychain_ttl
  end

  def self.config
    @config ||= Config.new.tap do |config|
      config.configuration_path = '/configuration'
      config.keychain_ttl = 3600
    end
  end

  def self.keychain
    @keychain ||= LruRedux::TTL::ThreadSafeCache.new(25, config.keychain_ttl)
  end

  class << self
    # safely fetches a subject from the id token after checking relevant claims and
    # verifying the signature.
    #
    # this may involve HTTP requests to fetch the issuer's configuration and JWKs.
    def subject_from(id_token)
      verifier = IDTokenVerifier.new(id_token, keychain)
      verifier.subject if verifier.verified?
    end

    def logout_url(return_to: nil)
      query = {redirect_uri: return_to}.to_param if return_to

      "#{Auth.config.issuer}/sessions/logout#{?? if query}#{query}"
    end
  end

end
