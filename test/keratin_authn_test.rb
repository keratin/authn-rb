require_relative 'test_helper'
require 'keratin/authn/testing'

class Keratin::AuthNTest < Keratin::AuthN::TestCase
  def setup
    Keratin::AuthN.keychain.clear
    super
  end

  test 'version number' do
    refute_nil ::Keratin::AuthN::VERSION
  end

  testing '.subject_from' do
    test 'with valid JWT' do
      stub_auth_server
      jwt = JSON::JWT.new(claims).sign(jws_keypair.to_jwk, 'RS256')
      assert_equal jwt['sub'], Keratin::AuthN.subject_from(jwt.to_s)
    end

    test 'with valid JWT containing audience array' do
      stub_auth_server
      jwt = JSON::JWT.new(claims.merge(aud: [claims[:aud]])).sign(jws_keypair.to_jwk, 'RS256')
      assert_equal jwt['sub'], Keratin::AuthN.subject_from(jwt.to_s)
    end

    test 'with invalid JWT' do
      assert_nil Keratin::AuthN.subject_from(nil)
      assert_nil Keratin::AuthN.subject_from('')
      assert_nil Keratin::AuthN.subject_from('a')
      assert_nil Keratin::AuthN.subject_from('a.b')
      assert_nil Keratin::AuthN.subject_from('a.b.c')
    end

    test 'with unsigned JWT' do
      stub_auth_server
      jwt = JSON::JWT.new(claims)
      assert_nil Keratin::AuthN.subject_from(jwt.to_s)
    end

    test 'with JWT signed by unknown keypair' do
      stub_auth_server
      some_key = OpenSSL::PKey::RSA.new(512)
      jwt = JSON::JWT.new(claims).sign(some_key, 'RS256')
      assert_nil Keratin::AuthN.subject_from(jwt.to_s)
    end

    test 'with tampered claims JWT' do
      stub_auth_server
      jwt = JSON::JWT.new(claims).sign(jws_keypair.to_jwk, 'RS256')
      jwt['sub'] = 999999
      assert_nil Keratin::AuthN.subject_from(jwt.to_s)
    end

    test 'with tampered alg=none JWT' do
      stub_auth_server
      jwt = JSON::JWT.new(claims).sign(jws_keypair.to_jwk, 'RS256')
      jwt.alg = 'none'
      jwt.signature = ''
      assert_nil Keratin::AuthN.subject_from(jwt.to_s)
    end

    test 'with tampered alg=hmac JWT' do
      stub_auth_server
      jwt = JSON::JWT.new(claims).sign(jws_keypair.public_key.to_jwk.to_s, 'HS256')
      assert_nil Keratin::AuthN.subject_from(jwt.to_s)

      jwt = JSON::JWT.new(claims).sign(jws_keypair.public_key.to_s, 'HS256')
      assert_nil Keratin::AuthN.subject_from(jwt.to_s)
    end

    test 'with cached keys' do
      Keratin::AuthN.keychain.instance_variable_get('@cache')[jws_keypair.to_jwk['kid']] = jws_keypair.to_jwk

      jwt = JSON::JWT.new(claims).sign(jws_keypair.to_jwk, 'RS256')
      assert_equal jwt['sub'], Keratin::AuthN.subject_from(jwt.to_s)
    end

    test 'with expired and stale issuer keys' do
      begin
        Timecop.freeze(Time.now)
        old = OpenSSL::PKey::RSA.new(512).to_jwk
        Keratin::AuthN.keychain.instance_variable_get('@cache')[old['kid']] = old
        Timecop.freeze(Time.now + Keratin::AuthN.config.keychain_ttl + 1)

        stub_auth_server
        jwt = JSON::JWT.new(claims).sign(jws_keypair.to_jwk, 'RS256')
        assert_equal jwt['sub'], Keratin::AuthN.subject_from(jwt.to_s)
      ensure
        Timecop.return
      end
    end

    test 'with valid JWT from different issuer' do
      evil_keypair = OpenSSL::PKey::RSA.new(512)
      stub_auth_server(issuer: 'https://evil.tech', keypair: evil_keypair)

      jwt = JSON::JWT.new(claims.merge(iss: 'https://evil.tech')).sign(evil_keypair, 'RS256')
      assert_nil Keratin::AuthN.subject_from(jwt.to_s)
    end

    test 'with valid JWT from same issuer with different formatting' do
      stub_auth_server
      jwt = JSON::JWT.new(claims.merge(iss: Keratin::AuthN.config.issuer + '/')).sign(jws_keypair.to_jwk, 'RS256')
      refute_equal jwt['iss'], Keratin::AuthN.config.issuer
      assert_equal jwt['sub'], Keratin::AuthN.subject_from(jwt.to_s)
    end

    test 'with valid JWT for different audience' do
      jwt = JSON::JWT.new(claims.merge(aud: 'https://evil.tech')).sign(jws_keypair.to_jwk, 'RS256')
      assert_nil Keratin::AuthN.subject_from(jwt.to_s)
    end

    test 'with expired JWT' do
      jwt = JSON::JWT.new(claims.merge(exp: (Time.now - 1).to_i)).sign(jws_keypair.to_jwk, 'RS256')
      assert_nil Keratin::AuthN.subject_from(jwt.to_s)
    end
  end

  testing '.subject_from.audience' do
    test 'with a matching audience' do
      stub_auth_server
      audience = 'another.tech'
      jwt = JSON::JWT.new(claims.merge(aud: audience)).sign(jws_keypair.to_jwk, 'RS256')
      assert_equal jwt['sub'], Keratin::AuthN.subject_from(jwt.to_s, audience: audience)
    end

    test 'without a matching audience' do
      stub_auth_server
      jwt = JSON::JWT.new(claims.merge(aud: 'first.tech')).sign(jws_keypair.to_jwk, 'RS256')
      assert_nil Keratin::AuthN.subject_from(jwt.to_s, audience: 'second.tech')
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

  private def stub_auth_server(issuer: Keratin::AuthN.config.issuer, keypair: jws_keypair)
    Keratin::AuthN.keychain.clear
    stub_request(:get, "#{issuer}/configuration").to_return(
      status: 200,
      body: {'jwks_uri' => "#{issuer}/jwks"}.to_json
    )
    stub_request(:get, "#{issuer}/jwks").to_return(
      status: 200,
      body: {
        keys: [
          keypair.public_key.to_jwk.slice(:kty, :kid, :e, :n).merge(
            use: 'sig',
            alg: 'RS256'
          )
        ]
      }.to_json
    )
  end

  private def jws_keypair
    @keypair ||= OpenSSL::PKey::RSA.new(512)
  end

end
