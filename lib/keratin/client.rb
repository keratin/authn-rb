module Keratin
  class Error < StandardError; end

  class ServiceResult
    attr_reader :data
    attr_reader :result

    def initialize(data)
      @data = data
      @result = data['result']
    end
  end

  class ClientError < Keratin::Error
    attr_reader :errors

    def initialize(errors)
      @errors = errors.map{|e| [e['field'], e['message']] }
        .group_by(&:first)
        .map{|k, v| [k, v.map(&:last)] }
        .to_h

      super(@errors.inspect)
    end
  end

  class ServiceError < Keratin::Error
  end

  class Client
    attr_reader :base

    def initialize(base_url, username: nil, password: nil)
      @base = base_url.chomp('/')
      @auth = [username, password] if username && password
    end

    private def get(**opts)
      submit(Net::HTTP::Get, **opts)
    end

    private def patch(**opts)
      submit(Net::HTTP::Patch, **opts)
    end

    private def delete(**opts)
      submit(Net::HTTP::Delete, **opts)
    end

    private def submit(request_klass, path:)
      uri = URI.parse("#{base}#{path}")

      request = request_klass.new(uri)
      request.basic_auth(*@auth) if @auth

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.open_timeout = 0.5
        http.read_timeout = 2.0

        case response = http.request(request)
        when Net::HTTPSuccess
          return ServiceResult.new(JSON.parse(response.body))
        when Net::HTTPRedirection
          return ServiceResult.new('result' => {
            'location' => response['Location']
          })
        when Net::HTTPClientError
          raise ClientError, JSON.parse(response.body)['errors']
        when Net::HTTPServerError
          raise ServiceError, response.body
        end
      end
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise ServiceError, e.message
    end
  end
end
