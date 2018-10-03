require 'fastlane_core/ui/ui'
require 'json'
require 'set'

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
    end
  end
end
