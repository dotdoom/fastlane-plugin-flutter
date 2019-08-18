require 'yaml'

module Fastlane
  module Helper
    class FlutterHelper
      def self.flutter(*argv, &block)
        # TODO(dotdoom): use CommandExecutor instead of Actions.sh.
        # TODO(dotdoom): explain special keys in params, like "log" etc.
        # TODO(dotdoom): most commands set "log: false", which means that the
        #                output is lost (even in case of error). Perhaps we
        #                could print the output here, via error_callback?
        # https://github.com/fastlane/fastlane/blob/b1495d134eec6681c8d7a544aa3520f1da00c80e/fastlane/lib/fastlane/helper/sh_helper.rb#L73
        Actions.sh(File.join(flutter_sdk_root, 'bin', 'flutter'), *argv, &block)
      end

      def self.git(*argv, &block)
        Actions.sh('git', *argv, &block)
      end

      def self.flutter_sdk_root
        @flutter_sdk_root ||= File.expand_path(
          if ENV.include?('FLUTTER_SDK_ROOT')
            ENV['FLUTTER_SDK_ROOT']
          elsif flutter_binary = FastlaneCore::CommandExecutor.which('flutter')
            File.dirname(File.dirname(flutter_binary))
          else
            'vendor/flutter'
          end
        )
      end

      def self.dev_dependency?(package)
        (YAML.load_file('pubspec.yaml')['dev_dependencies'] || {}).key?(package)
      end
    end
  end
end
