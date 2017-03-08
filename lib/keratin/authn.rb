require_relative 'authn/version'
require_relative 'authn/engine' if defined?(Rails)
require_relative 'authn/id_token_verifier'
require_relative 'authn/remote_signature_verifier'
require_relative 'authn/mock_signature_verifier'
require_relative 'authn/issuer'

require 'lru_redux'
require 'json/jwt'

module Keratin
  def self.authn
    @authn ||= AuthN::Issuer.new(
      AuthN.config.issuer,
      username: AuthN.config.username,
      password: AuthN.config.password
    )
  end

  module AuthN
    class Config
      # the domain (host) of the main application.
      # e.g. "audience.tech"
      attr_accessor :audience

      # the base url of the service handling authentication
      # e.g. "https://issuer.tech"
      attr_accessor :issuer

      # how long (in seconds) to keep keys in the keychain before refreshing.
      # default: 3600
      attr_accessor :keychain_ttl

      # the http basic auth username for accessing private endpoints of the authn issuer.
      attr_accessor :username

      # the http basic auth password for accessing private endpoints of the authn issuer.
      attr_accessor :password
    end

    def self.config
      @config ||= Config.new.tap do |config|
        config.keychain_ttl = 3600
      end
    end

    # The default strategy for signature verification will find the JWT's issuer, fetch the JWKs
    # from that server, choose the correct key by id, and finally verify the JWT. The keys are
    # then cached in memory to reduce network traffic.
    def self.signature_verifier
      @verifier ||= RemoteSignatureVerifier.new(
        LruRedux::TTL::ThreadSafeCache.new(25, config.keychain_ttl)
      )
    end

    # If the default strategy is not desired (as in host application tests), different strategies
    # may be specified here. The strategy must define a `verify(jwt)` method.
    def self.signature_verifier=(val)
      unless val.respond_to?(:verify) && val.method(:verify).arity == 1
        raise ArgumentError, 'Please ensure that your signature verifier has been instantiated and implements `def verify(jwt)`.'
      end

      @verifier = val
    end

    class << self
      # safely fetches a subject from the id token after checking relevant claims and
      # verifying the signature.
      def subject_from(id_token)
        verifier = IDTokenVerifier.new(id_token, signature_verifier)
        verifier.subject if verifier.verified?
      end

      def logout_url(return_to: nil)
        query = {redirect_uri: return_to}.to_param if return_to

        "#{config.issuer}/sessions/logout#{'?' if query}#{query}"
      end
    end
  end
end
