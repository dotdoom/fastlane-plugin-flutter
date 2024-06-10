# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'yaml'

require_relative 'flutter_helper'

module Fastlane
  module Helper
  end
end

module Fastlane
  module Helper
    class FlutterGenerateIntlHelper
      def self.generate(messages_filename, messages_locale = nil)
        dart_files_dirname = File.dirname(messages_filename)
        arb_files_dirname = File.join(dart_files_dirname, 'arb')
        full_arb_filename = generate_arb_from_dart(
          messages_filename, messages_locale, arb_files_dirname
        )

        arb_filenames = amend_arb_files(arb_files_dirname, full_arb_filename)

        unless messages_locale
          # Don't generate .dart for the ARB generated from original, unless it
          # has its own locale.
          arb_filenames.delete(full_arb_filename)
        end

        Fastlane::UI.message('Generating .dart files from .arb...')
        Fastlane::Helper::FlutterHelper.flutter(
          *%W[packages pub run intl_translation:generate_from_arb
              --output-dir=#{dart_files_dirname}
              --no-use-deferred-loading
              #{messages_filename}] + arb_filenames
        )
      end

      def self.amend_arb_files(arb_files_dirname, full_arb_filename)
        full_arb_json = JSON.parse(File.read(full_arb_filename))

        # Sort files for consistency, because generated messages_all.dart will
        # have imports ordered as in the command line below.
        arb_filenames = Dir.glob(File.join(arb_files_dirname, 'intl_*.arb')).sort
        arb_filenames.each do |arb_filename|
          arb_json = JSON.parse(File.read(arb_filename))
          if arb_filename != full_arb_filename
            Fastlane::UI.message("Amending #{arb_filename}...")
            full_arb_json.each_pair do |k, v|
              # Ignore @@keys. We don't want to copy @@locale over all files, and
              # it's often unspecified to be inferred from file name.
              arb_json[k] ||= v unless k.start_with?('@@')
            end
            arb_json.keep_if { |k| full_arb_json.key?(k) }
          end
          File.write(arb_filename, "#{JSON.pretty_generate(arb_json)}\n")
        end
      end

      def self.generate_arb_from_dart(dart_filename, dart_locale, arb_dirname)
        arb_filename = File.join(arb_dirname, 'intl_messages.arb')
        Fastlane::UI.message("Generating #{arb_filename} from #{dart_filename}...")

        if File.exist?(arb_filename)
          arb_file_was = File.read(arb_filename)
        else
          # The file may not exist on the first run. Then it's also probable that
          # the output directory does not exist yet.
          FileUtils.mkdir_p(arb_dirname)
        end

        extract_to_arb_options = ["--output-dir=#{arb_dirname}"]
        extract_to_arb_options.push("--locale=#{dart_locale}") if dart_locale

        Fastlane::Helper::FlutterHelper.flutter(
          *%w[packages pub run intl_translation:extract_to_arb],
          *extract_to_arb_options, dart_filename
        )

        # intl will update @@last_modified even if there are no updates; this
        # leaves Git directory unnecessary dirty. If that's the only change,
        # just restore the previous contents.
        if arb_file_was && restore_last_modified(arb_filename, arb_file_was)
          Fastlane::UI.message(
            "@@last_modified has been restored in #{arb_filename}"
          )
        end

        arb_filename
      end

      def self.restore_last_modified(filename, old_content)
        new_content_tree = JSON.parse(File.read(filename))
        old_content_tree = JSON.parse(old_content)
        new_content_tree['@@last_modified'] = old_content_tree['@@last_modified']

        # Use to_json to compare the objects deep and in consistent format.
        if new_content_tree.to_json == old_content_tree.to_json
          # Except for the @@last_modified attribute that we replaced
          # above, the objects are identical. Restore previous timestamp.
          File.write(filename, old_content)
          return true
        end

        false
      end
    end
  end
end
