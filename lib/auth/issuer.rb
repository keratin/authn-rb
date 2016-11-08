module Auth
  class Issuer
    def initialize(str)
      @uri = str
      @config_uri = @uri + Auth::CONFIG[:configuration_path]
    end

    def signing_key
      keys.find{|k| k['use'] == 'sig' }
    end

    def configuration
      @configuration ||= JSON.parse(
        Net::HTTP.get(URI.parse(@config_uri))
      )
    end

    def keys
      @keys ||= JSON::JWK::Set.new(
        JSON.parse(
          Net::HTTP.get(URI.parse(configuration['jwks_uri']))
        )
      )
    end
  end
end
