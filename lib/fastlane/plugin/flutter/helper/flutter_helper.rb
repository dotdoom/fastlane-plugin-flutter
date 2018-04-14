require 'fastlane_core/ui/ui'
require 'json'

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
    end
  end
end
