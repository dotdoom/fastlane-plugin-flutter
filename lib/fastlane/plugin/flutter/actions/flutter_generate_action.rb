require 'fastlane/action'
require_relative '../base/flutter_action_base'
require_relative '../helper/flutter_helper'
require_relative '../helper/flutter_generate_intl_helper'
require_relative '../helper/flutter_generate_build_runner_helper'

module Fastlane
  module Actions
    class FlutterGenerateAction < Action
      extend FlutterActionBase

      # Although this file is autogenerated, we should not call it ".g.dart",
      # because it is common for coverage configuration to exclude such files.
      # Note that it's also common to configure Dart analyser to exclude these
      # files from checks; this won't match, and we have to use ignore_for_file
      # for all known lint rules that we might be breaking.
      ALL_IMPORTS_TEST_FILE = 'test/all_imports_for_coverage_test.dart'

      def self.run(params)
        Helper::FlutterHelper.flutter(*%w(packages get)) {}

        if params[:coverage_all_imports] && File.exist?(ALL_IMPORTS_TEST_FILE)
          # This file may somehow confuse codegeneration (e.g. built_value).
          File.delete(ALL_IMPORTS_TEST_FILE)
        end

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

        if params[:coverage_all_imports]
          UI.message("Generating #{ALL_IMPORTS_TEST_FILE} for coverage...")

          File.write(
            ALL_IMPORTS_TEST_FILE,
            <<-DART
// This file is autogenerated by fastlane flutter_generate action.
// It imports all files in lib/ so that test coverage in percentage
// of overall project is calculated correctly. Do not modify this
// file manually!

// https://github.com/flutter/flutter/issues/27997#issuecomment-1644224366
// ignore: unused_import
import 'package:#{Helper::FlutterHelper.pub_package_name}/main.dart';

// Fake test in order to make each file reachable by the coverage
void main() {}
            DART
          )
        end
      end

      def self.generate_translation?
        Helper::FlutterHelper.dev_dependency?('intl_translation')
      end

      def self.description
        "(1) Run `flutter packages get`;  " \
        "(2) Run `build_runner build` if build_runner is in dev_dependencies;" \
        "   " \
        "(3) According to `package:intl`, take `$strings_file` and generate " \
        "`${strings_file.dirname}/arb/intl_messages.arb`, then take all " \
        "files matching `${strings_file.dirname}/intl_*.arb`, fix them and " \
        "generate .dart files from them.  " \
        "(4) Generate an empty test importing all files, which would be used " \
        "to calculate correct full coverage numbers."
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
          FastlaneCore::ConfigItem.new(
            key: :coverage_all_imports,
            env_name: 'FL_FLUTTER_COVERAGE_ALL_IMPORTS',
            description: <<-DESCRIPTION,
            Set to true to generate an empty test importing all .dart files in
            lib/, which would allow calculating correct coverage numbers for the
            whole project. NOTE: Don't forget to add
              /#{ALL_IMPORTS_TEST_FILE}
            to .gitignore!
            DESCRIPTION
            optional: true,
            type: Boolean,
          ),
        ]
      end
    end
  end
end
