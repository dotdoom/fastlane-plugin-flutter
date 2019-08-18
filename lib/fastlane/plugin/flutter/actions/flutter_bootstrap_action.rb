require 'fastlane/action'
require_relative '../base/flutter_action_base'
require_relative '../helper/flutter_helper'
require_relative '../helper/flutter_bootstrap_helper'

module Fastlane
  module Actions
    class FlutterBootstrapAction < Action
      extend FlutterActionBase

      def self.run(params)
        if params[:android_licenses]
          Helper::FlutterBootstrapHelper.accept_licenses(
            File.join(android_sdk_root!, 'licenses'),
            params[:android_licenses],
          )
        end

        # Upgrade or install Flutter SDK.
        flutter_sdk_root = Helper::FlutterHelper.flutter_sdk_root
        flutter_channel = params[:flutter_channel]
        if File.directory?(flutter_sdk_root)
          if flutter_channel
            UI.message("Making sure Flutter is on channel #{flutter_channel}")
            Helper::FlutterHelper.flutter('channel', flutter_channel) {}
          end
          if params[:flutter_auto_upgrade]
            UI.message("Upgrading Flutter SDK in #{flutter_sdk_root}...")
            Helper::FlutterHelper.flutter('upgrade') {}
          end
        else
          Helper::FlutterHelper.git(
            'clone', # no --depth to keep Flutter tag-based versioning.
            "--branch=#{flutter_channel || 'beta'}",
            '--quiet',
            '--',
            'https://github.com/flutter/flutter.git',
            flutter_sdk_root,
          )
        end
        UI.message('Precaching Flutter SDK binaries...')
        Helper::FlutterHelper.flutter('precache') {}
      end

      def self.android_sdk_root!
        (ENV['ANDROID_HOME'] || ENV['ANDROID_SDK_ROOT']).tap do |path|
          unless path
            UI.build_failure!('Android SDK directory environment variables ' \
              'are not set. See ' \
              'https://developer.android.com/studio/command-line/variables')
          end
        end
      end

      def self.description
        'Flutter SDK installation, upgrade and application bootstrap'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :flutter_channel,
            env_name: 'FL_FLUTTER_CHANNEL',
            description: 'Flutter SDK channel (keep existing if unset)',
            optional: true,
            type: String,
          ),
          FastlaneCore::ConfigItem.new(
            key: :flutter_auto_upgrade,
            env_name: 'FL_FLUTTER_AUTO_UPGRADE',
            description: 'Automatically upgrade Flutter when already installed',
            default_value: true,
            optional: true,
            is_string: false, # official replacement for "type: Boolean"
          ),
          FastlaneCore::ConfigItem.new(
            key: :android_licenses,
            description: 'Map of file names to hash values of accepted ' \
            'Android SDK linceses, which may be found in ' \
            '$ANDROID_SDK_ROOT/licenses/ on developer workstations. Gradle ' \
            'will refuse to install SDK unless licenses are accepted',
            optional: true,
            type: Hash,
          ),
        ]
      end
    end
  end
end
