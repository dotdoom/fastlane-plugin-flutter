require 'fastlane/action'
require_relative '../helper/flutter_helper'

module Fastlane
  module Actions
    module SharedValues
      FLUTTER_OUTPUT_APP = :FLUTTER_OUTPUT_APP
      FLUTTER_OUTPUT_APK = :FLUTTER_OUTPUT_APK
    end

    class FlutterAction < Action
      FLUTTER_ACTIONS = %(build analyze test format l10n)

      PLATFORM_TO_FLUTTER = {
        ios: 'ios',
        android: 'apk',
      }

      FLUTTER_TO_OUTPUT = {
        'ios' => SharedValues::FLUTTER_OUTPUT_APP,
        'apk' => SharedValues::FLUTTER_OUTPUT_APK,
      }

      def self.run(params)
        case params[:action]
        when 'build'
          flutter_platforms = %w(apk ios)
          # Override if we are on a specific platform (non-root lane).
          if fastlane_platform = lane_context[SharedValues::PLATFORM_NAME]
            flutter_platforms = [PLATFORM_TO_FLUTTER[fastlane_platform]]
          end

          additional_args = []
          additional_args.push('--debug') if params[:debug]

          flutter_platforms.each do |platform|
            sh('flutter', 'build', platform, *additional_args) do |status, res|
              if status.success?
                # Dirty hacks ahead!
                if FLUTTER_TO_OUTPUT.key?(platform)
                  # Examples:
                  # Built /Users/foo/src/flutter/build/output/my.app.
                  # Built /Users/foo/src/flutter/build/output/my.apk (32.4MB).
                  if res =~ /^Built (.*?)(:? \([^)]*\))?\.$/
                    lane_context[FLUTTER_TO_OUTPUT[platform]] =
                      File.absolute_path($1)
                  end
                end
              end
            end
          end
        when 'test'
          sh *%w(flutter test)
        when 'analyze'
          sh *%W(flutter analyze #{params[:lib_path]})
        when 'format'
          sh *%W(flutter format #{params[:lib_path]})
        when 'l10n'
          output_dir = File.join(params[:lib_path], 'l10n')
          sh *%W(flutter pub pub run intl_translation:extract_to_arb
            --output-dir=#{output_dir} #{params[:l10n_strings_file]})

          # messages_all.dart will have files ordered as in the command line.
          arb_files = Dir.glob(File.join(output_dir, 'intl_*.arb')).sort

          sh *%W(flutter pub pub run intl_translation:generate_from_arb
            --output-dir=#{output_dir}
            --no-use-deferred-loading
            #{params[:l10n_strings_file]}) + arb_files
        end
      end

      def self.description
        "Flutter actions plugin for Fastlane"
      end

      def self.authors
        ["Artem Sheremet"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        ""
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :action,
            env_name: 'FL_FLUTTER_ACTION',
            description: 'Flutter action to run',
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("Supported actions are: #{FLUTTER_ACTIONS}") unless FLUTTER_ACTIONS.include?(value)
            end,
          ),
          FastlaneCore::ConfigItem.new(
            key: :debug,
            env_name: 'FL_FLUTTER_DEBUG',
            description: 'Build a Debug version of the app if true',
            optional: true,
            is_string: false,
            default_value: false,
          ),
          FastlaneCore::ConfigItem.new(
            key: :lib_path,
            env_name: 'FL_FLUTTER_LIB_PATH',
            description: "Path to Flutter 'lib' directory",
            optional: true,
            default_value: 'lib',
            verify_block: proc do |value|
              UI.user_error!('Directory does not exist') unless Dir.exists?(value)
            end,
          ),
          FastlaneCore::ConfigItem.new(
            key: :l10n_strings_file,
            env_name: 'FL_FLUTTER_L10N_STRINGS',
            description: 'Path to the .dart file with l10n strings',
            optional: true,
            verify_block: proc do |value|
              UI.user_error!('File does not exist') unless File.exists?(value)
            end,
          ),
        ]
      end

      def self.is_supported?(platform)
        # Also support nil (root lane).
        [nil, :ios, :android].include?(platform)
      end
    end
  end
end
