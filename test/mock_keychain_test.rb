require_relative 'test_helper'

class Keratin::MockKeychainTest < Keratin::AuthN::TestCase
  def setup
    @_orig_keychain = Keratin::AuthN.keychain
    Keratin::AuthN.keychain = Keratin::AuthN::MockKeychain.new
  end

  def teardown
    Keratin::AuthN.keychain = @_orig_keychain
  end

  include Keratin::AuthN::Test::Helpers

  test 'host application test environment' do
    assert_equal 87632, Keratin::AuthN.subject_from(id_token_for(87632))
  end
end
