require_relative 'test_helper'
require 'keratin/authn/testing'

class Keratin::AuthNTest < Keratin::AuthN::TestCase
  include Keratin::AuthN::Test::Helpers

  test 'version number' do
    refute_nil ::Keratin::AuthN::VERSION
  end

  testing '.subject_from' do
    test "with valid JWT" do
      stub_auth_server
      jwt = JSON::JWT.new(claims).sign(jws_keypair, 'RS256')
      assert_equal jwt['sub'], Keratin::AuthN.subject_from(jwt.to_s)
    end

    test "with invalid JWT" do
      assert_nil Keratin::AuthN.subject_from(nil)
      assert_nil Keratin::AuthN.subject_from('')
      assert_nil Keratin::AuthN.subject_from('a')
      assert_nil Keratin::AuthN.subject_from('a.b')
      assert_nil Keratin::AuthN.subject_from('a.b.c')
    end

    test "with unsigned JWT" do
      stub_auth_server
      jwt = JSON::JWT.new(claims)
      assert_nil Keratin::AuthN.subject_from(jwt.to_s)
    end

    test "with JWT signed by unknown keypair" do
      stub_auth_server
      some_key = OpenSSL::PKey::RSA.new(512)
      jwt = JSON::JWT.new(claims).sign(some_key, 'RS256')
      assert_nil Keratin::AuthN.subject_from(jwt.to_s)
    end

    test "with tampered JWT" do
      stub_auth_server
      jwt = JSON::JWT.new(claims).sign(jws_keypair, 'RS256')
      jwt['sub'] = 999999
      assert_nil Keratin::AuthN.subject_from(jwt.to_s)
    end

    test "with cached issuer keys" do
      Keratin::AuthN.keychain[Keratin::AuthN.config.issuer] = jws_keypair.to_jwk

      jwt = JSON::JWT.new(claims).sign(jws_keypair, 'RS256')
      assert_equal jwt['sub'], Keratin::AuthN.subject_from(jwt.to_s)
    end

    test "with expired and stale issuer keys" do
      begin
        Timecop.freeze(Time.now)
        Keratin::AuthN.keychain[Keratin::AuthN.config.issuer] = OpenSSL::PKey::RSA.new(512).to_jwk
        Timecop.freeze(Time.now + Keratin::AuthN.config.keychain_ttl + 1)

        stub_auth_server
        jwt = JSON::JWT.new(claims).sign(jws_keypair, 'RS256')
        assert_equal jwt['sub'], Keratin::AuthN.subject_from(jwt.to_s)
      ensure
        Timecop.return
      end
    end

    test "with valid JWT from different issuer" do
      evil_keypair = OpenSSL::PKey::RSA.new(512)
      stub_auth_server(issuer: "https://evil.tech", keypair: evil_keypair)

      jwt = JSON::JWT.new(claims.merge(iss: 'https://evil.tech')).sign(evil_keypair, 'RS256')
      assert_nil Keratin::AuthN.subject_from(jwt.to_s)
    end

    test "with valid JWT from same issuer with different formatting" do
      stub_auth_server
      jwt = JSON::JWT.new(claims.merge(iss: Keratin::AuthN.config.issuer + '/')).sign(jws_keypair, 'RS256')
      refute_equal jwt['iss'], Keratin::AuthN.config.issuer
      assert_equal jwt['sub'], Keratin::AuthN.subject_from(jwt.to_s)
    end

    test "with valid JWT for different audience" do
      jwt = JSON::JWT.new(claims.merge(aud: 'https://evil.tech')).sign(jws_keypair, 'RS256')
      assert_nil Keratin::AuthN.subject_from(jwt.to_s)
    end

    test "with expired JWT" do
      jwt = JSON::JWT.new(claims.merge(exp: (Time.now - 1).to_i)).sign(jws_keypair, 'RS256')
      assert_nil Keratin::AuthN.subject_from(jwt.to_s)
    end
  end

  testing '.logout_url' do
    test 'with a next url' do
      assert_equal 'https://issuer.tech/sessions/logout?redirect_uri=https%3A%2F%2Fapp.tech', Keratin::AuthN.logout_url(return_to: 'https://app.tech')
    end

    test 'without a next url' do
      assert_equal 'https://issuer.tech/sessions/logout', Keratin::AuthN.logout_url
    end
  end

  private def claims
    {
      iss: Keratin::AuthN.config.issuer,
      aud: Keratin::AuthN.config.audience,
      sub: rand(999),
      iat: (Time.now - 5).to_i,
      exp: (Time.now + 150).to_i
    }
  end
end
