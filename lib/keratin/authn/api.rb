require 'keratin/client'
require 'net/http'

module Keratin::AuthN
  class API < Keratin::Client
    def update(account_id, username:)
      patch(path: "/accounts/#{account_id}", body: {
        username: username
      }).result
    end

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
  end
end
