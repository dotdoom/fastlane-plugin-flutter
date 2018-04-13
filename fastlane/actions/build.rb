module Fastlane
  module Actions
    class BuildAction < Action
      ALLOWED_TYPES = %w(apk ios)

      def self.run(params)
        UI.message "Building #{params[:build_type]}"
        sh "flutter build #{params[:build_type]}"
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "A short description with <= 80 characters of what this action does"
      end

      def self.details
        # Optional:
        # this is your chance to provide a more detailed description of this action
        "You can use this action to do cool things..."
      end

      def self.available_options
        # Define all options your action supports. 

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :build_type,
                                       env_name: "FL_FLUTTER_BUILD_TYPE",
                                       description: "Type of the app to build. Allowed types: #{ALLOWED_TYPES}",
                                       verify_block: proc do |value|
                                          UI.user_error!("Build type is not supported") unless ALLOWED_TYPES.include?(value)
                                       end),
        ]
      end

      def self.output
        []
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["Your GitHub/Twitter Name"]
      end

      def self.is_supported?(platform)
        # you can do things like
        # 
        #  true
        # 
        #  platform == :ios
        # 
        #  [:ios, :mac].include?(platform)
        # 

        platform == :ios
      end
    end
  end
end
