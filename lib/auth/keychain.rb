require_relative 'issuer'

module Auth
  # TODO: set TTL per issuer from caching headers in HTTP response.
  # TODO: race condition handling. use expired keys until refreshed.
  # TODO: crude LRU algorithm to prevent memory exhaustion DOS attack.
  # TODO: thread safety!
  class Keychain
    Record = Struct.new(:issuer, :expires_at, :signing_key) do
      def expired?
        expires_at < Time.now
      end
    end

    def initialize(ttl: 3600)
      @ttl = ttl
      clear
    end

    def fetch(issuer)
      if @records[issuer].nil? || @records[issuer].expired?
        store(issuer, Time.now + @ttl, Issuer.new(issuer).signing_key)
      end

      @records[issuer].signing_key
    end

    # this private method exists for tests only.
    private def clear
      @records = {}
    end

    # this private method exists for tests only.
    private def store(issuer, expires_at, signing_key)
      @records[issuer] = Record.new(issuer, expires_at, signing_key)
    end
  end
end
