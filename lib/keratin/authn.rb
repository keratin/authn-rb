require_relative 'authn/version'
require_relative 'authn/engine' if defined?(Rails)
require_relative 'authn/id_token_verifier'
require_relative 'authn/fetching_keychain'
require_relative 'authn/mock_keychain'
require_relative 'authn/api'

require 'lru_redux'
require 'json/jwt'

module Keratin
  # Client for AuthN API calls
  def self.authn
    @authn ||= AuthN::API.new(
      AuthN.config.authn_url,
      username: AuthN.config.username,
      password: AuthN.config.password
    )
  end

  module AuthN
    class Config
      # the domain (host) of the main application. no protocol.
      # e.g. "audience.tech"
      attr_accessor :audience

      # the base url of the service handling authentication
      # e.g. "https://issuer.tech"
      attr_accessor :issuer

      # the base url for API calls. this is useful if you've divided your network so private API
      # requests can not be probed by public devices. it is optional, and will default to issuer.
      # e.g. "https://authn.internal.dns"
      attr_writer :authn_url
      def authn_url
        @authn_url || issuer
      end

      # how long (in seconds) to keep keys in the keychain before refreshing.
      # default: 3600
      attr_accessor :keychain_ttl

      # the http basic auth username for accessing private endpoints of the authn issuer.
      attr_accessor :username

      # the http basic auth password for accessing private endpoints of the authn issuer.
      attr_accessor :password

      # optional logger for debug messages
      attr_accessor :logger
    end

    def self.config
      @config ||= Config.new.tap do |config|
        config.keychain_ttl = 3600
      end
    end

    def self.debug
      config.logger.debug{ yield } if config.logger
    end

    # The default keychain will fetch JWKs from AuthN and return the correct key by id. Keys are
    # cached in memory to reduce network traffic.
    def self.keychain
      @keychain ||= FetchingKeychain.new(issuer: config.authn_url, ttl: config.keychain_ttl)
    end

    # If the default keychain is not desired (as in host application tests), different keychain may
    # be specified here. The keychain must define a `[](kid)` method.
    def self.keychain=(val)
      unless val.respond_to?(:[]) && val.method(:[]).arity == 1
        raise ArgumentError, 'Please ensure that your keychain has been instantiated and implements `[](kid)`.'
      end

      @keychain = val
    end

    class << self
      # safely fetches a subject from the id token after checking relevant claims and
      # verifying the signature.
      def subject_from(id_token, audience: Keratin::AuthN.config.audience)
        verifier = IDTokenVerifier.new(id_token, keychain, audience)
        verifier.subject if verifier.verified?
      end
    end
  end
end
