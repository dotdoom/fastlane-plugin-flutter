require 'fastlane/action'
require_relative '../base/flutter_action_base'
require_relative '../helper/flutter_helper'
require_relative '../helper/flutter_bootstrap_helper'

module Fastlane
  module Actions
    class FlutterBootstrapAction < Action
      extend FlutterActionBase

      FLUTTER_REMOTE_REPOSITORY = 'https://github.com/flutter/flutter.git'

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
        if Helper::FlutterHelper.flutter_installed?
          if flutter_channel
            UI.message("Making sure Flutter is on channel #{flutter_channel}")
            Helper::FlutterHelper.flutter('channel', flutter_channel) {}
          end
          if params[:flutter_auto_upgrade] &&
             need_upgrade_to_channel?(flutter_sdk_root, flutter_channel)
            UI.message("Upgrading Flutter SDK in #{flutter_sdk_root}...")
            Helper::FlutterHelper.flutter('upgrade') {}
          end
        else
          Helper::FlutterHelper.git(
            'clone', # no --depth limit to keep Flutter tag-based versioning.
            "--branch=#{flutter_channel || 'beta'}",
            '--quiet',
            '--',
            FLUTTER_REMOTE_REPOSITORY,
            flutter_sdk_root,
          )
        end

        UI.message('Precaching Flutter SDK binaries...')
        Helper::FlutterHelper.flutter('precache') {}
      end

      def self.need_upgrade_to_channel?(flutter_sdk_root, flutter_channel)
        # No channel specified -- always upgrade.
        return true unless flutter_channel

        remote_hash = Helper::FlutterHelper.git(
          'ls-remote', FLUTTER_REMOTE_REPOSITORY, flutter_channel
        ) do |status, output, errors_thread|
          output.split[0].strip if status.success?
        end
        local_hash = Helper::FlutterHelper.git(
          '-C', flutter_sdk_root, 'rev-parse', 'HEAD'
        ) do |status, output, errors_thread|
          output.strip if status.success?
        end

        if local_hash != nil && local_hash == remote_hash
          UI.message("Local and remote Flutter repository hashes match " \
                     "(#{local_hash}), no upgrade necessary. Keeping Git " \
                     "index untouched!")
          false
        else
          UI.message("Local hash (#{local_hash}) of Flutter repository " \
                     "differs from remote (#{remote_hash}), upgrading")
          true
        end
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
