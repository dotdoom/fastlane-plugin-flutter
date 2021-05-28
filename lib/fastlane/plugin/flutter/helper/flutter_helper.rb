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
        vendor_flutter_path = File.join(Dir.pwd, 'vendor', 'flutter')
        @flutter_sdk_root ||= File.expand_path(
          if flutter_installed?(vendor_flutter_path)
            vendor_flutter_path
          elsif flutter_installed?(File.join(Dir.pwd, '.flutter'))
            # Support flutterw and compatible projects.
            File.join(Dir.pwd, '.flutter')
          elsif ENV.include?('FLUTTER_SDK_ROOT')
            UI.deprecated(
              'FLUTTER_SDK_ROOT environment variable is deprecated. ' \
              'To point to a Flutter installation directory, use ' \
              'FLUTTER_ROOT instead.'
            )
            ENV['FLUTTER_SDK_ROOT']
          elsif ENV.include?('FLUTTER_ROOT')
            # FLUTTER_ROOT is a standard environment variable from Flutter.
            ENV['FLUTTER_ROOT']
          elsif flutter_binary = FastlaneCore::CommandExecutor.which('flutter')
            File.dirname(File.dirname(flutter_binary))
          else
            # Where we'd prefer to install flutter.
            File.join(Dir.pwd, 'vendor', 'flutter')
          end
        )
      end

      def self.flutter_installed?(custom_flutter_root = nil)
        # Can't use File.executable? because on Windows it has to be .exe.
        File.exist?(flutter_binary(custom_flutter_root))
      end

      def self.flutter_binary(custom_flutter_root = nil)
        File.join(custom_flutter_root || flutter_sdk_root, 'bin', 'flutter')
      end

      def self.dev_dependency?(package)
        (YAML.load_file('pubspec.yaml')['dev_dependencies'] || {}).key?(package)
      end

      def self.pub_package_name
        YAML.load_file('pubspec.yaml')['name']
      end

      def self.import_path_for_test(file_to_import, relative_path)
        unless file_to_import.start_with?('lib/')
          return File.join(relative_path, file_to_import)
        end

        # Import file schema in tests have to match files in lib/ exactly. From
        # Dart perspective, symbols in files imported via relative and
        # "package:" file paths are different symbols.
        package_specification = "package:#{pub_package_name}/"
        if File.read(file_to_import, 4096).include?(package_specification)
          # If there's a package reference in the first few bytes of the file,
          # chances are, it's using "package:..." imports. Indeed, checking the
          # file itself isn't sufficient to explore all of its dependencies, but
          # we expect imports to be consistent in the project.
          "#{package_specification}#{file_to_import['lib/'.size..-1]}"
        else
          File.join(relative_path, file_to_import)
        end
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
