require 'net/http'

module Keratin::AuthN
  class Issuer
    def initialize(str)
      @base = str.chomp('/')
    end

    def signing_key
      keys.find{|k| k['use'] == 'sig' }
    end

    def configuration
      @configuration ||= get(path: Keratin::AuthN.config.configuration_path)
    end

    def keys
      @keys ||= JSON::JWK::Set.new(
        get(url: configuration['jwks_uri'])
      )
    end

    private def get(path: nil, url: nil)
      uri = URI.parse(url || "#{@base}#{path}")

      JSON.parse(Net::HTTP.get(uri))
    end
  end
end
