require_relative 'test_helper'

class Keratin::FetchingKeychainTest < Keratin::AuthN::TestCase
  def subject
    @subject ||= Keratin::AuthN::FetchingKeychain.new(issuer: 'https://issuer.tech', ttl: 3600)
  end

  testing '#signing_key' do
    test 'with multiple keys' do
      stub = stub_request(:get, 'https://issuer.tech/jwks').to_return(body: {
        'keys' => [
          {'use' => 'sig', 'kid' => 'key1', 'foo' => 'bar'},
          {'use' => 'sig', 'kid' => 'key2', 'foo' => 'baz'}
        ]
      }.to_json)

      assert_equal 'baz', subject['key2']['foo']
      assert_requested(stub)
    end

    test 'after key rotation' do
      stub_request(:get, 'https://issuer.tech/jwks').to_return(body: {
        'keys' => [
          {'use' => 'sig', 'kid' => 'key1', 'foo' => 'bar'},
          {'use' => 'sig', 'kid' => 'key2', 'foo' => 'baz'}
        ]
      }.to_json)

      assert_equal 'bar', subject['key1']['foo']
      assert_equal 'baz', subject['key2']['foo']

      stub_request(:get, 'https://issuer.tech/jwks').to_return(body: {
        'keys' => [
          {'use' => 'sig', 'kid' => 'key2', 'foo' => 'baz'},
          {'use' => 'sig', 'kid' => 'key3', 'foo' => 'qux'}
        ]
      }.to_json)

      assert_equal 'baz', subject['key2']['foo']
      assert_equal 'qux', subject['key3']['foo']
    end
  end
end
