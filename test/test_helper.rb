$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'keratin/authn'

require 'minitest/autorun'

Keratin::AuthN.config.issuer = "https://issuer.tech"
Keratin::AuthN.config.audience = "audience.tech"

require 'timecop'

class Keratin::AuthN::TestCase < Minitest::Test
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
