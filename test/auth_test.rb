require 'test_helper'

class AuthTest < Auth::TestCase
  test 'version number' do
    refute_nil ::Auth::VERSION
  end

  test 'it does something useful' do
    assert false
  end
end
