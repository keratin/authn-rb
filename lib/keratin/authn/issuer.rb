require 'keratin/client'
require 'net/http'

module Keratin::AuthN
  class Issuer < Keratin::Client
    def initialize(str)
      @base = str.chomp('/')
    end

    def signing_key
      keys.find{|k| k['use'] == 'sig' }
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
