require 'fastlane/action'
require_relative '../helper/flutter_helper'

# This is the entry point for this plugin. For more information on writing
# plugins: https://docs.fastlane.tools/advanced/

module Fastlane
  module Actions
    module SharedValues
      FLUTTER_OUTPUT_APP = :FLUTTER_OUTPUT_APP
      FLUTTER_OUTPUT_APK = :FLUTTER_OUTPUT_APK
      FLUTTER_OUTPUT_GIT_BUILD_NUMBER = :FLUTTER_OUTPUT_GIT_BUILD_NUMBER
      FLUTTER_OUTPUT_GIT_BUILD_NAME = :FLUTTER_OUTPUT_GIT_BUILD_NAME
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

          if params[:git_version]
            build_number = sh(*%w(git rev-list --count HEAD)).strip.to_i
            lane_context[SharedValues::FLUTTER_OUTPUT_GIT_BUILD_NUMBER] =
              build_number
            additional_args.push('--build-number', build_number.to_s)

            build_name = sh(
              *%W(
                git describe
                --tags
                --dirty=#{params[:git_version_dirty_mark]}
              )
            ).strip
            lane_context[SharedValues::FLUTTER_OUTPUT_GIT_BUILD_NAME] =
              build_name
            additional_args.push('--build-name', build_name)
          end

          built_files = {}

          flutter_platforms.each do |platform|
            sh('flutter', 'build', platform, *additional_args) do |status, res|
              if status.success?
                # Dirty hacks ahead!
                if FLUTTER_TO_OUTPUT.key?(platform)
                  # Examples:
                  # Built /Users/foo/src/flutter/build/output/myapp.app.
                  # Built build/output/myapp.apk (32.4MB).
                  if res =~ /^Built (.*?)(:? \([^)]*\))?\.$/
                    built_file = File.absolute_path($1)
                    built_files[PLATFORM_TO_FLUTTER.key(platform)] = built_file
                    lane_context[FLUTTER_TO_OUTPUT[platform]] = built_file
                  end
                end
              else
                # fastlane does not fail automatically if we provide a block.
                UI.user_error!("flutter build #{platform} has failed.")
              end
            end
          end

          built_files
        when 'test'
          sh *%w(flutter test)
        when 'analyze'
          sh *%w(flutter analyze)
        when 'format'
          sh *%w(flutter format .)
        when 'l10n'
          run_l10n(params)
        end
      end

      def self.run_l10n(params)
        unless params[:l10n_strings_file]
          UI.user_error!('l10n_strings_file is a required parameter for ' \
                         'l10n action')
        end

        output_dir = 'lib/l10n'
        l10n_messages_file = File.join(output_dir, 'intl_messages.arb')
        # This file will not exist before it's generated for the first time.
        if File.exist?(l10n_messages_file)
          l10n_messages_was = File.read(l10n_messages_file)
        end

        extract_to_arb_options = ["--output-dir=#{output_dir}"]
        if params[:l10n_strings_locale]
          extract_to_arb_options.push(
            "--locale=#{params[:l10n_strings_locale]}"
          )
        end

        sh *%w(flutter pub pub run intl_translation:extract_to_arb),
           *extract_to_arb_options, params[:l10n_strings_file]

        if l10n_messages_was
          # intl will update @@last_modified even if there are no updates;
          # this leaves Git directory unnecessary dirty. If that's the only
          # change, just restore the previous contents.
          if Helper::FlutterHelper.restore_l10n_timestamp(
            l10n_messages_file, l10n_messages_was
          )
            UI.message(
              "@@last_modified has been restored in #{l10n_messages_file}"
            )
          end
        end

        # Sort files for consistency, because messages_all.dart will have
        # imports ordered as in the command line below.
        arb_files = Dir.glob(File.join(output_dir, 'intl_*.arb')).sort

        if params[:l10n_verify_arb]
          errors_found = arb_files.any? do |arb_file|
            unless arb_file == l10n_messages_file
              UI.message("Verifying #{arb_file}...")
              errors = Helper::FlutterHelper.compare_arb(l10n_messages_file,
                                                         arb_file)
              if errors.any?
                errors.each { |e| UI.error(e) }
              end
            end
          end
          UI.user_error!('Found inconsistencies in ARB files') if errors_found
        end

        unless params[:l10n_strings_locale]
          # Don't generate .dart for the original ARB unless it has its own
          # locale.
          arb_files.delete(l10n_messages_file)
        end

        if params[:l10n_reformat_arb]
          arb_files.each do |arb_file|
            UI.message("Reformatting file #{arb_file}...")
            Helper::FlutterHelper.reformat_arb(arb_file)
          end
        end

        sh *%W(flutter pub pub run intl_translation:generate_from_arb
               --output-dir=#{output_dir}
               --no-use-deferred-loading
               #{params[:l10n_strings_file]}) + arb_files
      end

      def self.description
        "Flutter actions plugin for Fastlane"
      end

      def self.authors
        ["Artem Sheremet"]
      end

      def self.return_value
        'For "build" action, the return value is a mapping of fastlane ' \
          'platform names into built output files, e.g.: ' +
          { android: '/Users/foo/src/flutter/build/outputs/myapp.apk' }.inspect
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
            key: :git_version,
            env_name: 'FL_FLUTTER_GIT_VERSION',
            description: 'Set build number and name based on Git',
            optional: true,
            is_string: false,
            default_value: false,
          ),
          FastlaneCore::ConfigItem.new(
            key: :git_version_dirty_mark,
            env_name: 'FL_FLUTTER_GIT_VERSION_DIRTY_MARK',
            description: 'Append mark if the working tree is "dirty"',
            optional: true,
            default_value: '*',
          ),
          # l10n settings
          FastlaneCore::ConfigItem.new(
            key: :l10n_strings_file,
            env_name: 'FL_FLUTTER_L10N_STRINGS',
            description: 'Path to the .dart file with l10n strings',
            optional: true,
            verify_block: proc do |value|
              UI.user_error!('File does not exist') unless File.exist?(value)
            end,
          ),
          FastlaneCore::ConfigItem.new(
            key: :l10n_strings_locale,
            env_name: 'FL_FLUTTER_L10N_STRINGS_LOCALE',
            description: 'Locale of the data in l10n_strings_file',
            optional: true,
          ),
          FastlaneCore::ConfigItem.new(
            key: :l10n_reformat_arb,
            env_name: 'FL_FLUTTER_L10N_REFORMAT_ARB',
            description: 'Reformat .arb files',
            optional: true,
            is_string: false,
            default_value: false,
          ),
          FastlaneCore::ConfigItem.new(
            key: :l10n_verify_arb,
            env_name: 'FL_FLUTTER_L10N_VERIFY_ARB',
            description: 'Verify that each .arb file includes all strings',
            optional: true,
            is_string: false,
            default_value: true,
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
