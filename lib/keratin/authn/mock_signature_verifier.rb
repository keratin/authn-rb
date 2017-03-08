module Keratin::AuthN
  class MockSignatureVerifier
    def verify(_)
      true
    end
  end
end
