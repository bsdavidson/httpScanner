# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'http_scanner/version'

Gem::Specification.new do |spec|
  spec.name          = 'http_scanner'
  spec.version       = HttpScanner::VERSION
  spec.authors       = ['Brian Davidson']
  spec.email         = ['bsdavidson@gmail.com']

  spec.summary       = %q{A small Ruby gem that will scan your local network for running HTTP services and return an array IP addresses.}
  spec.homepage      = 'https://github.com/bsdavidson/http_scanner'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'simplecov', '~> 0.11.2'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'redcarpet', '~> 3.3'
  spec.add_development_dependency 'rspec', '~> 3.3'
  spec.add_development_dependency 'yard', '~> 0.8'
end
