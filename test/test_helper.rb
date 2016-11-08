$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'auth'

require 'minitest/autorun'

class Auth::TestCase < Minitest::Test
  def self.testing(name, &block)
    raise "already testing #{@testing}" if @testing
    @testing = name
    yield
  ensure
    @testing = nil
  end

  def self.test(name, &block)
    method_name = ['test', @testing, name].compact.join(' ').gsub(' ', '_')
    if block_given?
      define_method method_name, &block
    else
      define_method method_name do
        skip "not implemented"
      end
    end
  end
end
