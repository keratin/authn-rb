module Keratin::AuthN
  class Engine < ::Rails::Engine
    initializer 'keratin.authn.testing' do
      require 'keratin/authn/testing' if Rails.env.test?
    end
  end
end
