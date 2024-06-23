# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'simplecov'

unless ENV['CODECOV_TOKEN'].to_s.empty?
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
  warn('SimpleCov formatter set to Codecov')
end
SimpleCov.start

# This module is only used to check the environment is currently a testing env
module SpecHelper
end

require 'fastlane' # to import the Action super class
require 'fastlane/plugin/flutter' # import the actual plugin

Fastlane.load_actions # load other actions (in case your plugin calls other actions or shared values)

def successful_flutter(output)
  status = double
  allow(status).to receive(:success?).and_return(true)
  [status, output]
end
