require 'fastlane_core/ui/ui'
require 'fileutils'
require 'json'
require 'set'
require 'tempfile'

module Fastlane
  # UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class FlutterHelper
      def self.restore_l10n_timestamp(file_name, old_content)
        new_content_tree = JSON.parse(File.read(file_name))
        old_content_tree = JSON.parse(old_content)

        new_content_tree['@@last_modified'] =
          old_content_tree['@@last_modified']

        # Use to_json to compare the objects deep and in consistent format.
        if new_content_tree.to_json == old_content_tree.to_json
          # Except for the @@last_modified attribute that we replaced
          # above, the objects are identical. Restore previous timestamp.
          File.write(file_name, old_content)
          return true
        end

        false
      end

      def self.reformat_arb(file_name)
        pretty_content = JSON.pretty_generate(JSON.parse(File.read(file_name)))

        File.write(file_name, pretty_content + "\n")
      end

      def self.compare_arb(origin, sample)
        is_significant_key = ->(key) { !key.start_with?('@') }

        origin_keys = Set.new(JSON.parse(File.read(origin))
          .keys
          .select(&is_significant_key))
        sample_keys = Set.new(JSON.parse(File.read(sample))
          .keys
          .select(&is_significant_key))

        keys_not_in_sample = origin_keys - sample_keys
        keys_not_in_origin = sample_keys - origin_keys

        differencies = []
        if keys_not_in_sample.any?
          differencies.push("Translation string(s): " \
                            "#{keys_not_in_sample.to_a.join(', ')}; " \
                            "are missing")
        end
        if keys_not_in_origin.any?
          differencies.push("Translation string(s): " \
                            "#{keys_not_in_origin.to_a.join(', ')}; " \
                            "are unused")
        end
        differencies
      end

      def self.build_number(schema)
        schema and Integer(schema)
      rescue ArgumentError
        build_number_source, build_number_base = schema.split('+', 2)

        case build_number_source
        when 'vcs'
          build_number = Integer(
            Actions.sh(*%w(git rev-list --count HEAD)).strip
          )
        when 'ci'
          begin
            build_number = Integer(ENV['TRAVIS_BUILD_NUMBER'] ||
                                   ENV['CIRCLE_BUILD_NUM'])
          rescue ArgumentError, TypeError
            raise if ENV.key?('CI')
            raise ArgumentError, 'CI version requested, but not running on a CI'
          end
        end

        if build_number_base
          build_number + Integer(build_number_base)
        else
          build_number
        end
      end

      def self.build_name(schema)
        if schema && schema =~ /^(\^)?vcs(.*)$/
          schema_caret = $1
          schema_dirty_mark = $2
          vcs_version = Actions.sh(
            *%W(git describe --tags --dirty=#{schema_dirty_mark})
          ).strip

          # We try to match, otherwise assume vcs_version = $TAG, which means
          # that there are 0 commits since the latest tag.
          if schema_caret && vcs_version =~ /^
                  (\d+[.]\d+)-
                  (\d+)-
                  g.*?
                  (#{Regexp.quote(schema_dirty_mark)})?
                $/x

            vcs_version = "#{$1}.#{$2}"
            # Making the best guess whether it's dirty.
            if $3
              vcs_version += schema_dirty_mark
            end
          end

          vcs_version
        else
          schema
        end
      end

      # Bootstrap Flutter application for build with Android SDK:
      # https://github.com/flutter/flutter/issues/28076
      def self.bootstrap_android(licenses = {})
        # Gradle will refuse to install Android SDK unless the SDK directory
        # exists and licenses are accepted.
        licenses_directory = File.join(android_sdk_root!, 'licenses')
        FileUtils.mkdir_p(licenses_directory)
        if licenses.any?
          licenses.each_pair do |license, hash|
            license_file = File.join(licenses_directory, license)
            unless File.exist?(license_file) &&
                   File.readlines(license_file).map(&:strip).include?(hash)
              File.open(license_file, 'a') { |f| f.puts('', hash) }
            end
          end
        end
      end

      def self.android_sdk_root!
        (ENV['ANDROID_HOME'] || ENV['ANDROID_SDK_ROOT']).tap do |path|
          unless path
            raise 'Android SDK directory environment variables are not set. ' \
              'See https://developer.android.com/studio/command-line/variables'
          end
        end
      end
    end
  end
end
