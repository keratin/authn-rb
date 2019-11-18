# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'keratin/authn/version'

Gem::Specification.new do |spec|
  spec.name          = 'keratin-authn'
  spec.version       = Keratin::AuthN::VERSION
  spec.authors       = ['Lance Ivy']
  spec.email         = ['lance@cainlevy.net']
  spec.license       = 'LGPL-3.0'

  spec.summary       = 'Client gem for keratin/authn service.'
  # spec.description   = ''
  spec.homepage      = 'https://github.com/keratin/authn-rb'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    # spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'json-jwt', '~> 1.11'
  spec.add_dependency 'lru_redux'

  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'coveralls'
end
