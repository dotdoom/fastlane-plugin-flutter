require 'fastlane/action'
require_relative '../base/flutter_action_base'
require_relative '../helper/flutter_helper'

module Fastlane
  module Actions
    class FlutterAction < Action
      extend FlutterActionBase

      def self.run(params)
        Helper::FlutterHelper.flutter(*params[:args])
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
        ]
      end
    end
  end
end
