require 'fastlane/action'
require_relative '../base/flutter_action_base'
require_relative '../helper/flutter_helper'

module Fastlane
  module Actions
    class FlutterAction < Action
      extend FlutterActionBase

      def self.run(params)
        if params[:capture_stdout]
          Helper::FlutterHelper.flutter(*params[:args]) do |status, output|
            output
          end
        else
          Helper::FlutterHelper.flutter(*params[:args])
        end
      end

      def self.description
        'Run "flutter" binary with the specified arguments'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :args,
            env_name: 'FL_FLUTTER_ARGS',
            description: 'Arguments to Flutter command',
            type: Array,
          ),
          FastlaneCore::ConfigItem.new(
            key: :capture_stdout,
            env_name: 'FL_FLUTTER_CAPTURE_STDOUT',
            description: 'Do not print stdout of the command, but return it',
            optional: true,
            type: Boolean,
            default_value: false,
          ),
        ]
      end
    end
  end
end
