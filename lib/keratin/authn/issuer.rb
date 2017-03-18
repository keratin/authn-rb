require 'keratin/client'
require 'net/http'

module Keratin::AuthN
  class Issuer < Keratin::Client
    def lock(account_id)
      patch(path: "/accounts/#{account_id}/lock").result
    end

    def unlock(account_id)
      patch(path: "/accounts/#{account_id}/unlock").result
    end

    def archive(account_id)
      delete(path: "/accounts/#{account_id}").result
    end

    # returns account_id or raises exception
    def import(username:, password:, locked: false)
      post(path: '/accounts/import', body: {
        username: username,
        password: password,
        locked: locked
      }).result['id']
    end

    def expire_password(account_id)
      patch(path: "/accounts/#{account_id}/expire_password")
    end

    def signing_key(kid)
      keys.find{|k| k['use'] == 'sig' && (kid.blank? || kid == k['kid']) }
    end

    private def configuration
      @configuration ||= get(path: '/configuration').data
    end

    private def keys
      JSON::JWK::Set.new(
        JSON.parse(
          Net::HTTP.get(URI.parse(configuration['jwks_uri']))
        )
      )
    end
  end
end
