require 'fastlane_core/ui/ui'
require 'fileutils'

module Fastlane
  module Helper
    class FlutterBootstrapHelper
      def self.accept_licenses(licenses_directory, licenses)
        FileUtils.mkdir_p(licenses_directory)
        licenses.each_pair do |license, hash|
          license_file = File.join(licenses_directory, license)
          next if File.exist?(license_file) &&
                  File.readlines(license_file).map(&:strip).include?(hash)
          UI.message("Updating Android SDK license in #{license_file}...")
          File.open(license_file, 'a') { |f| f.puts('', hash) }
        end
      end
    end
  end
end
