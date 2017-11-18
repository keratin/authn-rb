module Keratin::AuthN
  class MockKeychain
    def [](kid)
      true
    end
  end
end
