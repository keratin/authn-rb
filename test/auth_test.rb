require 'test_helper'
require 'auth/testing'

class AuthTest < Auth::TestCase
  include Auth::Test::Helpers

  test 'version number' do
    refute_nil ::Auth::VERSION
  end

  testing '#subject_from' do
    test "with invalid JWT" do
      assert_equal nil, Auth.subject_from(nil)
      assert_equal nil, Auth.subject_from('')
      assert_equal nil, Auth.subject_from('a')
      assert_equal nil, Auth.subject_from('a.b')
      assert_equal nil, Auth.subject_from('a.b.c')
    end

    test "with unsigned JWT" do
      stub_auth_server
      jwt = JSON::JWT.new(claims)
      assert_equal nil, Auth.subject_from(jwt.to_s)
    end

    test "with JWT signed by unknown keypair" do
      stub_auth_server
      some_key = OpenSSL::PKey::RSA.new(512)
      jwt = JSON::JWT.new(claims).sign(some_key, 'RS256')
      assert_equal nil, Auth.subject_from(jwt.to_s)
    end

    test "with tampered JWT" do
      stub_auth_server
      jwt = JSON::JWT.new(claims).sign(jws_keypair, 'RS256')
      jwt['sub'] = 999999
      assert_equal nil, Auth.subject_from(jwt.to_s)
    end

    test "with valid JWT for different audience" do
      jwt = JSON::JWT.new(claims.merge(aud: 'https://evil.tech')).sign(jws_keypair, 'RS256')
      assert_equal nil, Auth.subject_from(jwt.to_s)
    end

    test "with stale JWT" do
      jwt = JSON::JWT.new(claims.merge(iat: (Time.now - 86400).to_i)).sign(jws_keypair, 'RS256')
      assert_equal nil, Auth.subject_from(jwt.to_s)
    end

    test "with expired JWT" do
      jwt = JSON::JWT.new(claims.merge(exp: (Time.now - 1).to_i)).sign(jws_keypair, 'RS256')
      assert_equal nil, Auth.subject_from(jwt.to_s)
    end
  end

  private def claims
    {
      iss: Auth.config.issuer,
      aud: Auth.config.audience,
      sub: rand(999),
      iat: (Time.now - 5).to_i,
      exp: (Time.now + 150).to_i
    }
  end
end
