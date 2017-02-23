module Keratin::AuthN
  class RemoteSignatureVerifier
    attr_reader :keychain

    def initialize(keychain)
      @keychain = keychain
    end

    def verify(jwt)
      jwt.verify!(key(jwt['iss'], jwt.kid))
    rescue JSON::JWT::VerificationFailed, JSON::JWT::UnexpectedAlgorithm
      false
    end

    private def key(issuer, kid)
      keychain.getset(kid){ Issuer.new(issuer).signing_key(kid) }
    end
  end
end
