module Keratin::AuthN
  class MockKeychain
    # a temporary RSA key for the test suite.
    #
    # generates the smallest (fastest) key possible for RS256
    def initialize
      @keypair ||= OpenSSL::PKey::RSA.new(512).to_jwk
    end

    def key
      @keypair
    end

    def [](_)
      key
    end
  end
end
