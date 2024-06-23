# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/flutter/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-flutter'
  spec.version       = Fastlane::Flutter::VERSION
  spec.author        = 'Artem Sheremet'
  spec.email         = 'artem@sheremet.ch'

  spec.summary       = 'Flutter actions plugin for Fastlane'
  spec.homepage      = 'https://github.com/dotdoom/fastlane-plugin-flutter'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*'] + %w[README.md LICENSE]
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  # spec.add_dependency 'your-dependency', '~> 1.0.0'

  spec.add_development_dependency('bundler')
  spec.add_development_dependency('codecov')
  spec.add_development_dependency('fastlane', '>= 2.91.0')
  spec.add_development_dependency('pry')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rspec')
  spec.add_development_dependency('rspec_junit_formatter')
  spec.add_development_dependency('rubocop', '~> 1.64')
  spec.add_development_dependency('rubocop-rake')
  spec.add_development_dependency('rubocop-require_tools')
  spec.add_development_dependency('rubocop-rspec')
  spec.add_development_dependency('simplecov')
end
