# frozen_string_literal: true

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
        # Support flutterw and compatible projects.
        # Prefixing directory name with "." has a nice effect that Flutter tools
        # such as "format" and "lint" will not recurse into this subdirectory
        # while analyzing the project itself. This works immensely better than
        # e.g. vendor/flutter.
        pinned_flutter_path = File.join(Dir.pwd, '.flutter')

        @flutter_sdk_root ||= File.expand_path(
          if flutter_installed?(pinned_flutter_path)
            UI.message("Determined Flutter location as #{pinned_flutter_path}" \
              " because 'flutter' executable exists there.")
            pinned_flutter_path
          elsif ENV.include?('FLUTTER_ROOT')
            # FLUTTER_ROOT is a standard environment variable from Flutter.
            UI.message("Determined Flutter location as #{ENV['FLUTTER_ROOT']}" \
              ' because environment variable FLUTTER_ROOT points there' \
              " (current directory is #{Dir.pwd}).")
            ENV['FLUTTER_ROOT']
          elsif (flutter_binary = FastlaneCore::CommandExecutor.which('flutter'))
            location = File.dirname(File.dirname(flutter_binary))
            UI.message("Determined Flutter location as #{location} because"\
              " 'flutter' executable in PATH is located there" \
              " (current directory is #{Dir.pwd}).")
            location
          else
            # Where we'd prefer to install flutter.
            UI.message('Determined desired Flutter location as' \
              " #{pinned_flutter_path} because that's where this fastlane" \
              ' plugin would install Flutter by default.')
            pinned_flutter_path
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
        return File.join(relative_path, file_to_import) unless file_to_import.start_with?('lib/')

        # Import file schema in tests have to match files in lib/ exactly. From
        # Dart perspective, symbols in files imported via relative and
        # "package:" file paths are different symbols.
        package_specification = "package:#{pub_package_name}/"
        if File.read(file_to_import, 4096).include?(package_specification)
          # If there's a package reference in the first few bytes of the file,
          # chances are, it's using "package:..." imports. Indeed, checking the
          # file itself isn't sufficient to explore all of its dependencies, but
          # we expect imports to be consistent in the project.
          "#{package_specification}#{file_to_import['lib/'.size..]}"
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
            UI.shell_error!(<<~ERROR)
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
