# frozen_string_literal: true

require 'fastlane/action'
require_relative '../base/flutter_action_base'
require_relative '../helper/flutter_helper'

module Fastlane
  module Actions
    module SharedValues
      FLUTTER_OUTPUT = :FLUTTER_OUTPUT
    end

    class FlutterBuildAction < Action
      extend FlutterActionBase

      FASTLANE_PLATFORM_TO_BUILD = {
        ios: 'ios',
        android: 'apk'
      }.freeze

      def self.run(params)
        # "flutter build" args list.
        build_args = []

        if params[:build]
          build_args.push(params[:build])
        elsif (fastlane_platform = lane_context[SharedValues::PLATFORM_NAME] ||
                                  lane_context[SharedValues::DEFAULT_PLATFORM])
          build_args.push(FASTLANE_PLATFORM_TO_BUILD[fastlane_platform])
        else
          UI.user_error!('flutter_build action "build" parameter is not ' \
          'specified and cannot be inferred from Fastlane context.')
        end

        process_deprecated_params(params, build_args)

        build_args.push('--debug') if params[:debug]

        if (build_number = params[:build_number] ||
                           lane_context[SharedValues::BUILD_NUMBER])
          build_args.push('--build-number', build_number.to_s)
        end

        if (build_name = params[:build_name] ||
                         lane_context[SharedValues::VERSION_NUMBER])
          build_args.push('--build-name', build_name.to_s)
        end

        build_args += params[:build_args] || []

        Helper::FlutterHelper.flutter('build', *build_args) do |status, res|
          if status.success?
            process_build_output(res, build_args)
            # gym (aka build_ios_app) action call may follow build; let's help
            # it identify the project, since Flutter project structure is
            # usually standard.
            publish_gym_defaults(build_args)
            if (build_args.include?('--verbose'))
              UI.command_output(res)
            end
          else
            # Print stdout from "flutter build" because it may contain useful
            # details about failures, and it's normally not very verbose.
            UI.command_output(res)
          end
          # Tell upstream to NOT ignore error.
          false
        end

        # Fill in some well-known context variables so that next commands may
        # pick them up.
        case params[:build]
        when 'apk'
          lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH] =
            lane_context[SharedValues::FLUTTER_OUTPUT]
        when 'appbundle'
          lane_context[SharedValues::GRADLE_AAB_OUTPUT_PATH] =
            lane_context[SharedValues::FLUTTER_OUTPUT]
        end

        lane_context[SharedValues::FLUTTER_OUTPUT]
      end

      def self.publish_gym_defaults(build_args)
        ENV['GYM_WORKSPACE'] ||= 'ios/Runner.xcworkspace'
        ENV['GYM_BUILD_PATH'] ||= 'build/ios'
        ENV['GYM_OUTPUT_DIRECTORY'] ||= 'build'
        return if ENV.include?('GYM_SCHEME')

        # Do some parsing on args. Is there a less ugly way?
        build_args.each.with_index do |arg, index|
          if arg.start_with?('--flavor', '-flavor')
            ENV['GYM_SCHEME'] = if arg.include?('=')
                                  arg.split('=', 2).last
                                else
                                  build_args[index + 1]
                                end
          end
        end
      end

      def self.process_deprecated_params(params, build_args)
        return if params[:codesign].nil?

        UI.deprecated(<<~"MESSAGE")
          flutter_build parameter "codesign" is deprecated. Use

            flutter_build(
              build_args: ["--#{params[:codesign] == false ? 'no-' : ''}codesign"]
            )

          form instead.
        MESSAGE

        return unless params[:codesign] == false

        build_args.push('--no-codesign')
      end

      def self.process_build_output(output, build_args)
        artifacts = output.scan(/Built (.*?)(:? \([^)]*\))?[.]?$/)
                          .map { |path| File.absolute_path(path[0]) }
        if artifacts.size == 1
          lane_context[SharedValues::FLUTTER_OUTPUT] = artifacts.first
        elsif artifacts.size > 1
          # Could be the result of "flutter build apk --split-per-abi".
          lane_context[SharedValues::FLUTTER_OUTPUT] = artifacts
        elsif build_args.include?('--config-only')
          UI.message('Config-only "build" detected, no output file name')
        else
          UI.important('Cannot parse built file path from "flutter build"')
        end
      end

      def self.description
        'Run "flutter build" to build a Flutter application'
      end

      def self.category
        :building
      end

      def self.return_value
        'A path to the built file, if available'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :build,
            env_name: 'FL_FLUTTER_BUILD',
            description: 'Type of Flutter build (e.g. apk, appbundle, ios)',
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :debug,
            env_name: 'FL_FLUTTER_DEBUG',
            description: 'Build a Debug version of the app if true',
            optional: true,
            type: Boolean,
            default_value: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :codesign,
            env_name: 'FL_FLUTTER_CODESIGN',
            description: 'Set to false to skip iOS app signing. This may be ' \
            'useful e.g. on CI or when signed later by Fastlane "sigh"',
            optional: true,
            type: Boolean
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_number,
            env_name: 'FL_FLUTTER_BUILD_NUMBER',
            description: 'Override build number specified in pubspec.yaml',
            optional: true,
            type: Integer
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_name,
            env_name: 'FL_FLUTTER_BUILD_NAME',
            description: <<-'DESCRIPTION',
              Override build name specified in pubspec.yaml.
              NOTE: for App Store, build name must be in the format of at most 3
                    integeres separated by a dot (".").
            DESCRIPTION
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_args,
            description: 'An array of extra arguments for "flutter build"',
            optional: true,
            type: Array
          )
        ]
      end
    end
  end
end
