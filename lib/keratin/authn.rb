require_relative 'authn/version'
require_relative 'authn/engine' if defined?(Rails)
require_relative 'authn/id_token_verifier'
require_relative 'authn/remote_signature_verifier'
require_relative 'authn/issuer'

require 'lru_redux'
require 'json/jwt'

module Keratin
  def self.authn
    @authn ||= AuthN::Issuer.new(AuthN.config.issuer,
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

    def self.signature_verifier
      @verifier ||= RemoteSignatureVerifier.new(
        LruRedux::TTL::ThreadSafeCache.new(25, config.keychain_ttl)
      )
    end

    class << self
      # safely fetches a subject from the id token after checking relevant claims and
      # verifying the signature.
      #
      # this may involve HTTP requests to fetch the issuer's configuration and JWKs.
      def subject_from(id_token)
        verifier = IDTokenVerifier.new(id_token, signature_verifier)
        verifier.subject if verifier.verified?
      end

      def logout_url(return_to: nil)
        query = {redirect_uri: return_to}.to_param if return_to

        "#{config.issuer}/sessions/logout#{?? if query}#{query}"
      end
    end
  end
end
