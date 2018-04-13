require 'fastlane/action'
require_relative '../helper/flutter_helper'
require 'shellwords'

module Fastlane
  module Actions
    module SharedValues
      FLUTTER_OUTPUT_FILE = :FLUTTER_OUTPUT_FILE
    end

    class FlutterAction < Action
      FLUTTER_ACTIONS = %(build analyze test format l10n)

      PLATFORM_TO_FLUTTER = {
        ios: 'ios',
        android: 'apk',
      }

      def self.run(params)
        case params[:action]
        when 'build'
          debug_key = '--debug' if params[:debug]
          flutter_platforms = %w(apk ios)

          # Override if we are on a specific platform (non-root lane).
          if fastlane_platform = lane_context[SharedValues::PLATFORM_NAME]
            flutter_platforms = [PLATFORM_TO_FLUTTER[fastlane_platform]]
          end

          flutter_platforms.each do |platform|
            sh "flutter build #{platform} #{debug_key}"
          end
        when 'test'
          sh 'flutter test'
        when 'analyze'
          sh "flutter analyze #{params[:lib_path].shellescape}"
        when 'format'
          sh "flutter format #{params[:lib_path].shellescape}"
        when 'l10n'
          output_dir = File.join(params[:lib_path], 'l10n')
          sh 'flutter pub pub run intl_translation:extract_to_arb ' +
            "--output-dir=#{output_dir.shellescape} " +
            "#{params[:l10n_strings_file].shellescape}"
          sh 'flutter pub pub run intl_translation:generate_from_arb ' +
            "--output-dir=#{output_dir.shellescape} " +
            "--no-use-deferred-loading " +
            "#{params[:l10n_strings_file].shellescape} " +
            "#{output_dir.shellescape}/intl_*.arb"
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
            description: 'true if Flutter should build a Debug version of the app',
            optional: true,
            type: true.class,
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
