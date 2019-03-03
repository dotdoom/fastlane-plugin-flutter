require 'fastlane/action'
require_relative '../base/flutter_action_base'
require_relative '../helper/flutter_helper'
require_relative '../helper/flutter_generate_intl_helper'
require_relative '../helper/flutter_generate_build_runner_helper'

module Fastlane
  module Actions
    class FlutterGenerateAction < Action
      extend FlutterActionBase

      def self.run(params)
        Helper::FlutterHelper.flutter(*%w(packages get), log: false)

        # In an ideal world, this should be a part of build_runner:
        # https://github.com/dart-lang/intl_translation/issues/32
        # Generate Intl messages before others, since these are static and
        # others may be not.
        if generate_translation?
          Helper::FlutterGenerateIntlHelper.generate(
            params[:intl_strings_file], params[:intl_strings_locale]
          )
        end

        if Helper::FlutterHelper.dev_dependency?('build_runner')
          UI.message('Found build_runner dependency, running build...')
          Helper::FlutterGenerateBuildRunnerHelper.build
        end
      end

      def self.generate_translation?
        Helper::FlutterHelper.dev_dependency?('intl_translation')
      end

      def self.description
        'According to package:intl, take $strings_file and generate ' \
        '${strings_file.dirname}/arb/intl_messages.arb, then take all files ' \
        'matching ${strings_file.dirname}/intl_*.arb, fix them and generate ' \
        '.dart files from them'
      end

      def self.available_options
        # https://docs.fastlane.tools/advanced/actions/#configuration-files
        [
          FastlaneCore::ConfigItem.new(
            key: :intl_strings_file,
            env_name: 'FL_FLUTTER_INTL_STRINGS_FILE',
            description: 'Path to source .dart file with Intl.message calls',
            verify_block: proc do |value|
              if generate_translation?
                unless File.exist?(value)
                  UI.user_error!("File `#{value}' does not exist")
                end
              end
            end,
            default_value: 'lib/intl/intl.dart',
          ),
          FastlaneCore::ConfigItem.new(
            key: :intl_strings_locale,
            env_name: 'FL_FLUTTER_INTL_STRINGS_LOCALE',
            description: 'Locale of the default data in the strings_file',
            optional: true,
          ),
        ]
      end
    end
  end
end
