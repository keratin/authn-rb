module Keratin::AuthN
  class FetchingKeychain
    def initialize(issuer:, ttl:)
      @cache = LruRedux::TTL::ThreadSafeCache.new(25, ttl)
      @issuer = issuer.chomp('/')
    end

    def [](kid)
      @cache.getset(kid){ fetch(kid) }
    end

    def clear
      @cache.clear
    end

    private def fetch(kid)
      keys = JSON::JWK::Set.new(
        JSON.parse(
          Net::HTTP.get(URI.parse("#{@issuer}/jwks"))
        )
      )
      keys.find{|k| k['use'] == 'sig' && (kid.blank? || kid == k['kid']) }
    end
  end
end
