require 'keratin/client'
require 'net/http'

module Keratin::AuthN
  class Issuer < Keratin::Client
    def lock(account_id)
      patch(path: "/accounts/:account_id/lock").result
    end

    def unlock(account_id)
      patch(path: "/accounts/:account_id/unlock").result
    end

    def archive(account_id)
      delete(path: "/accounts/:account_id").result
    end

    def signing_key(kid)
      keys.find{|k| k['use'] == 'sig' && (kid.blank? || kid == k['kid']) }
    end

    def configuration
      @configuration ||= get(path: '/configuration').data
    end

    def keys
      @keys ||= JSON::JWK::Set.new(
        get(path: URI.parse(configuration['jwks_uri']).path).data
      )
    end
  end
end
