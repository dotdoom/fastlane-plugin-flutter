# frozen_string_literal: true

require 'fastlane/action'

module Fastlane
  module Actions
    module FlutterActionBase
      def authors
        ['github.com/dotdoom']
      end

      def is_supported?(platform)
        # Also support nil (root lane).
        [nil, :ios, :android].include?(platform)
      end
    end
  end
end
