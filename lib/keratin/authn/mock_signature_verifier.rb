module Keratin::AuthN
  class MockSignatureVerifier
    def verify(jwt)
      true
    end
  end
end
