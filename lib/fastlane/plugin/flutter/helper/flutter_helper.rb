require 'shellwords'
require 'yaml'

module Fastlane
  module Helper
    class FlutterHelper
      def self.flutter(*argv, &block)
        execute(flutter_binary, *argv, &block)
      end

      def self.git(*argv, &block)
        execute('git', *argv, &block)
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

      def self.flutter_installed?
        # Can't use File.executable? because on Windows it has to be .exe.
        File.exist?(flutter_binary)
      end

      def self.flutter_binary
        File.join(flutter_sdk_root, 'bin', 'flutter')
      end

      def self.dev_dependency?(package)
        (YAML.load_file('pubspec.yaml')['dev_dependencies'] || {}).key?(package)
      end

      def self.execute(*command)
        # TODO(dotdoom): make CommandExecutor (and Actions.sh) behave similarly.
        command = command.shelljoin
        UI.command(command)
        Open3.popen3(command) do |stdin, stdout, stderr, wait_thread|
          errors_thread = Thread.new { stderr.read }
          stdin.close

          if block_given?
            output = stdout.read
            ignore_error = yield(wait_thread.value, output, errors_thread)
          else
            stdout.each_line do |stdout_line|
              UI.command_output(stdout_line.chomp)
            end
          end

          unless wait_thread.value.success? || (ignore_error == true)
            UI.shell_error!(<<-ERROR)
The following command has failed:

$ #{command}
[#{wait_thread.value}]

#{errors_thread.value}
ERROR
          end

          ignore_error
        end
      end
    end
  end
end
