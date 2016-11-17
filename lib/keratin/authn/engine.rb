module Keratin::AuthN
  class Engine < ::Rails::Engine
    initializer 'auth.testing' do
      require 'auth/testing' if Rails.env.test?
    end
  end
end
