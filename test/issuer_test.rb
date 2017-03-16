require_relative 'test_helper'

class Keratin::IssuerTest < Keratin::AuthN::TestCase
  def subject
    @subject ||= Keratin::AuthN::Issuer.new(
      Keratin::AuthN.config.issuer,
      username: 'foo',
      password: 'bar'
    )
  end

  test '#lock' do
    stub = stub_request(:patch, 'https://issuer.tech/accounts/123/lock').to_return(body: '{}')
    subject.lock(123)
    assert_requested(stub)
  end

  test '#unlock' do
    stub = stub_request(:patch, 'https://issuer.tech/accounts/123/unlock').to_return(body: '{}')
    subject.unlock(123)
    assert_requested(stub)
  end

  test '#archive' do
    stub = stub_request(:delete, 'https://issuer.tech/accounts/123').to_return(body: '{}')
    subject.archive(123)
    assert_requested(stub)
  end

  testing '#import' do
    test 'success' do
      stub_request(:post, 'https://issuer.tech/accounts/import').to_return(body: '{"result":{"id":123}}')
      assert_equal 123, subject.import(username: 'username', password: 'password')
    end

    test 'failure' do
      stub_request(:post, 'https://issuer.tech/accounts/import').to_return(status: 422, body: '{"errors": [{"field":"username","message":"MISSING"}]}')
      assert_raises Keratin::Error do
        subject.import(username: 'username', password: 'password')
      end
    end
  end

  testing '#signing_key' do
    test 'with multiple keys' do
      stub_request(:get, 'https://issuer.tech/configuration').to_return(body: {'jwks_uri' => 'https://issuer.tech/jwks'}.to_json)
      stub = stub_request(:get, 'https://issuer.tech/jwks').to_return(body: {
        'keys' => [
          {'use' => 'sig', 'kid' => 'key1', 'foo' => 'bar'},
          {'use' => 'sig', 'kid' => 'key2', 'foo' => 'baz'}
        ]
      }.to_json)

      assert_equal 'baz', subject.signing_key('key2')['foo']
      assert_requested(stub)
    end

    test 'after key rotation' do
      stub_request(:get, 'https://issuer.tech/configuration').to_return(body: {'jwks_uri' => 'https://issuer.tech/jwks'}.to_json)
      stub_request(:get, 'https://issuer.tech/jwks').to_return(body: {
        'keys' => [
          {'use' => 'sig', 'kid' => 'key1', 'foo' => 'bar'},
          {'use' => 'sig', 'kid' => 'key2', 'foo' => 'baz'}
        ]
      }.to_json)

      assert_equal 'bar', subject.signing_key('key1')['foo']
      assert_equal 'baz', subject.signing_key('key2')['foo']

      stub_request(:get, 'https://issuer.tech/jwks').to_return(body: {
        'keys' => [
          {'use' => 'sig', 'kid' => 'key2', 'foo' => 'baz'},
          {'use' => 'sig', 'kid' => 'key3', 'foo' => 'qux'}
        ]
      }.to_json)

      assert_equal 'baz', subject.signing_key('key2')['foo']
      assert_equal 'qux', subject.signing_key('key3')['foo']
    end
  end
end
