require 'fileutils'

describe Fastlane::Helper::FlutterHelper do
  describe 'flutter_sdk_root detects "flutter" path' do
    before :each do
      # Make sure there's no "flutter" in PATH.
      ENV['PATH'] = ENV['PATH'].gsub('flutter', '__removed__')
      ENV['FLUTTER_ROOT'] = nil
      # Remove ".flutter" pinned version in case it was installed by e2e.
      FileUtils.rm_rf('.flutter')

      # A terrible hack to reset the cache.
      Fastlane::Helper::FlutterHelper.instance_variable_set(:@flutter_sdk_root,
                                                            nil)
    end

    it 'with FLUTTER_ROOT' do
      Dir.mktmpdir('fastlane-plugin-flutter-spec-') do |d|
        ENV['FLUTTER_ROOT'] = d
        expect(Fastlane::Helper::FlutterHelper.flutter_sdk_root).
          to eq(d)
      end
    end

    it 'with "flutter" executable in PATH' do
      flutter_root = Dir.mktmpdir('fastlane-plugin-flutter-spec-')
      begin
        flutter_bin = File.join(flutter_root, 'bin')
        Dir.mkdir(flutter_bin)
        flutter_executable = File.join(flutter_bin, 'flutter')
        File.write(flutter_executable, 'echo')
        File.chmod(0755, flutter_executable)
        File.write(flutter_executable + '.bat', 'echo')
        ENV['PATH'] = [ENV['PATH'], flutter_bin].join(File::PATH_SEPARATOR)
        expect(Fastlane::Helper::FlutterHelper.flutter_sdk_root).
          to eq(flutter_root)
      ensure
        FileUtils.rm_rf(flutter_root)
      end
    end

    it 'without hints' do
      expect(Fastlane::Helper::FlutterHelper.flutter_sdk_root).
        to eq(File.join(Dir.pwd, '.flutter'))
    end
  end
end
