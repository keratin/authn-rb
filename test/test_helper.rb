$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'coveralls'
Coveralls.wear!

require 'keratin/authn'

require 'byebug'
require 'minitest/autorun'
require 'timecop'
require 'webmock/minitest'

Keratin::AuthN.config.issuer = 'https://issuer.tech'
Keratin::AuthN.config.audience = 'audience.tech'

class Keratin::AuthN::TestCase < Minitest::Test
  def self.testing(name)
    raise "already testing #{@testing}" if @testing
    @testing = name
    yield
  ensure
    @testing = nil
  end

  def self.test(name, &block)
    method_name = ['test', @testing, name].compact.join(' ').tr(' ', '_')
    if block_given?
      define_method method_name, &block
    else
      define_method method_name do
        skip 'not implemented'
      end
    end
  end
end
