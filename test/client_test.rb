require_relative 'test_helper'

class Keratin::ClientTest < Keratin::AuthN::TestCase
  BASE = "https://example.service"
  BASIC_AUTH = {basic_auth: ['hello', 'world']}

  def client
    @client ||= Keratin::Client.new(BASE, username: 'hello', password: 'world')
  end

  testing '#initialize' do
    test 'normalizing path' do
      assert_equal BASE, Keratin::Client.new(BASE).base
      assert_equal BASE, Keratin::Client.new(BASE + '/').base
    end
  end

  testing '#get' do
    test 'with path' do
      stub = stub_request(:get, "#{BASE}/some/path")
        .with(BASIC_AUTH)
        .to_return(body: "{}")

      client.send(:get, path: '/some/path')

      assert_requested(stub)
    end
  end

  testing '#patch' do
    test 'with path' do
      stub = stub_request(:patch, "#{BASE}/some/path")
        .with(BASIC_AUTH)
        .to_return(body: "{}")

      client.send(:patch, path: '/some/path')

      assert_requested(stub)
    end
  end

  testing '#delete' do
    test 'with path' do
      stub = stub_request(:delete, "#{BASE}/some/path")
        .with(BASIC_AUTH)
        .to_return(body: "{}")

      client.send(:delete, path: '/some/path')

      assert_requested(stub)
    end
  end

  testing 'response:' do
    test '2xx' do
      stub = stub_request(:get, "#{BASE}/some/path")
        .with(BASIC_AUTH)
        .to_return(status: 200, body: '{"result": [1,2,3]}')

      response = client.send(:get, path: '/some/path')
      assert response.is_a?(Keratin::ServiceResult)
      assert_equal [1, 2, 3], response.result
    end

    test '3xx' do
      stub = stub_request(:get, "#{BASE}/some/path")
        .with(BASIC_AUTH)
        .to_return(status: 302, headers: {'Location' => 'https://example.com'})

      response = client.send(:get, path: '/some/path')
      assert response.is_a?(Keratin::ServiceResult)
      assert_equal 'https://example.com', response.result['location']
    end

    test '4xx' do
      stub = stub_request(:get, "#{BASE}/some/path")
        .with(BASIC_AUTH)
        .to_return(status: 404, body: '{"errors": [{"field": "account", "message": "NOT_FOUND"}]}')

      begin
        client.send(:get, path: '/some/path')
      rescue Keratin::ClientError => response
        assert_equal [{"field"=>"account", "message"=>"NOT_FOUND"}], response.errors
      end
    end

    test '5xx' do
      stub = stub_request(:get, "#{BASE}/some/path")
        .with(BASIC_AUTH)
        .to_return(status: 500, body: "500 WHOOPS")

      begin
        client.send(:get, path: '/some/path')
      rescue Keratin::ServiceError => response
        assert_equal '500 WHOOPS', response.message
      end
    end

    test 'timeout' do
      stub = stub_request(:get, "#{BASE}/some/path")
        .with(BASIC_AUTH)
        .to_raise(Net::OpenTimeout.new('could not connect'))

      begin
        client.send(:get, path: '/some/path')
      rescue Keratin::ServiceError => response
        assert_equal 'could not connect', response.message
      end

    end
  end
end
