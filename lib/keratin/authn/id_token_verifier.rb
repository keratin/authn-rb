require 'uri'

module Keratin::AuthN
  class IDTokenVerifier
    def initialize(str, signature_verifier, audience)
      @id_token = str
      @signature_verifier = signature_verifier
      @audience = audience
      @time = Time.now.to_i
    end

    def subject
      jwt['sub']
    end

    EXPECTATIONS = [
      :token_exists?,
      :token_from_us?,
      :token_for_us?,
      :token_fresh?,
      :token_intact?
    ]

    def verified?
      EXPECTATIONS.all? do |expectation|
        if send(expectation)
          true
        else
          Keratin::AuthN.debug{ "JWT failure: #{expectation}" }
          false
        end
      end
    end

    def token_exists?
      !jwt.nil? && !jwt.blank?
    end

    def token_from_us?
      # the server or client may be configured with an extra trailing slash, unnecessary port number,
      # or something else that is an equivalent URI but not an equivalent string.
      URI.parse(jwt[:iss]) == URI.parse(Keratin::AuthN.config.issuer)
    end

    def token_for_us?
      jwt[:aud] == @audience
    end

    def token_fresh?
      jwt[:exp] > @time
    end

    def token_intact?
      @signature_verifier.verify(jwt)
    end

    private def jwt
      return @jwt if defined? @jwt
      @jwt = JSON::JWT.decode(@id_token || '', :skip_verification)
    rescue JSON::JWT::InvalidFormat
      @jwt = nil
    end
  end
end
