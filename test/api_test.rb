require_relative 'test_helper'

class Keratin::APITest < Keratin::AuthN::TestCase
  def subject
    @subject ||= Keratin::AuthN::API.new(
      Keratin::AuthN.config.issuer,
      username: 'foo',
      password: 'bar'
    )
  end

  test '#get' do
    stub = stub_request(:get, 'https://issuer.tech/accounts/123').to_return(body: '{"result": {"id": 123, "username": "username", "locked": false, "deleted": false}}')
    assert_equal 'username', subject.get(123).result['username']
  end

  testing '#update' do
    test 'success' do
      stub = stub_request(:patch, 'https://issuer.tech/accounts/123').to_return(body: '{}')
      subject.update(123, username: 'new')
    end

    test 'failure' do
      stub = stub_request(:patch, 'https://issuer.tech/accounts/123').to_return(status: 422, body: '{"errors": [{"field":"username","message":"MISSING"}]}')
      assert_raises Keratin::Error do
        subject.update(123, username: '')
      end
    end
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

  testing '#expire_password' do
    test 'success' do
      stub = stub_request(:patch, 'https://issuer.tech/accounts/123/expire_password').to_return(body: '{}')
      subject.expire_password(123)
      assert_requested(stub)
    end
  end
end
