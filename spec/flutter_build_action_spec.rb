describe Fastlane::Actions::FlutterBuildAction do
  describe '#run' do
    after :each do
      Fastlane::FastFile.new.parse(<<-FASTLANE).runner.execute(:test)
        lane :test do
          lane_context[SharedValues::FLUTTER_OUTPUT] = nil
          lane_context[SharedValues::BUILD_NUMBER] = nil
          lane_context[SharedValues::VERSION_NUMBER] = nil
        end
      FASTLANE

      ENV['GYM_SCHEME'] = nil
    end

    describe 'parses' do
      it 'output from "flutter build"' do
        expect(Fastlane::Helper::FlutterHelper).
          to receive(:flutter).and_yield(*successful_flutter(<<-BUILD_LOG))
        Running task :assembleDebug...
        Searching for the ring...
        Built path/to/app-debug.apk.
        BUILD_LOG
        value = Fastlane::FastFile.new.parse(<<-FASTLANE).runner.execute(:test)
          lane :test do
            flutter_build(build: 'apk')
          end
        FASTLANE
        # Prepend "fastlane" because that's what runner will do.
        expect(value).to eq(File.join(Dir.pwd, 'fastlane/path/to/app-debug.apk'))
      end

      it 'multiple outputs from "flutter build"' do
        expect(Fastlane::Helper::FlutterHelper).
          to receive(:flutter).and_yield(*successful_flutter(<<-BUILD_LOG))
        Running task :assembleDebug...
        Searching for the ring...
        Built path/to/app-armv7-debug.apk.
        Built path/to/app-x86-debug.apk.
        BUILD_LOG
        value = Fastlane::FastFile.new.parse(<<-FASTLANE).runner.execute(:test)
          lane :test do
            flutter_build(build: 'apk')
          end
        FASTLANE
        expect(value).to eq(
          [
            File.join(Dir.pwd, 'fastlane/path/to/app-armv7-debug.apk'),
            File.join(Dir.pwd, 'fastlane/path/to/app-x86-debug.apk'),
          ]
        )
      end
    end

    describe 'command line' do
      it 'apk debug' do
        expect(Fastlane::Helper::FlutterHelper).
          to receive(:flutter).
          with('build', 'apk', '--debug').
          and_yield(*successful_flutter(''))
        Fastlane::FastFile.new.parse(<<-FASTLANE).runner.execute(:test)
          lane :test do
            flutter_build(build: 'apk', debug: true)
          end
        FASTLANE
      end

      it 'build_name / build_number' do
        expect(Fastlane::Helper::FlutterHelper).
          to receive(:flutter).
          with(
            'build', 'apk', '--debug',
            '--build-number', '456',
            '--build-name', '1.2.3',
          ).
          and_yield(*successful_flutter(''))
        Fastlane::FastFile.new.parse(<<-FASTLANE).runner.execute(:test)
          lane :test do
            flutter_build(build: 'apk', debug: true,
                          build_name: '1.2.3',
                          build_number: 456)
          end
        FASTLANE
      end

      it 'build_name / build_number from lane context' do
        expect(Fastlane::Helper::FlutterHelper).
          to receive(:flutter).
          with(
            'build', 'apk',
            '--build-number', '654',
            '--build-name', '3.2.1',
          ).
          and_yield(*successful_flutter(''))
        Fastlane::FastFile.new.parse(<<-FASTLANE).runner.execute(:test)
          lane :test do
            lane_context[SharedValues::BUILD_NUMBER] = 654
            lane_context[SharedValues::VERSION_NUMBER] = '3.2.1'
            flutter_build(build: 'apk')
          end
        FASTLANE
      end

      it 'build type from fastlane platform' do
        expect(Fastlane::Helper::FlutterHelper).
          to receive(:flutter).
          with('build', 'ios', '--debug').
          and_yield(*successful_flutter(''))
        Fastlane::FastFile.new.parse(<<-FASTLANE).runner.execute(:test)
          default_platform(:ios)
          lane :test do
            flutter_build(debug: true)
          end
        FASTLANE
      end

      it 'build type from fastlane platform (no-codesign builds)' do
        expect(Fastlane::Helper::FlutterHelper).
          to receive(:flutter).
          with('build', 'ios', '--no-codesign').
          and_yield(*successful_flutter(''))
        Fastlane::FastFile.new.parse(<<-FASTLANE).runner.execute(:test)
          default_platform(:ios)
          lane :test do
            flutter_build(build_args: %w(--no-codesign))
          end
        FASTLANE
      end

      it 'build type from fastlane platform (release builds)' do
        expect(Fastlane::Helper::FlutterHelper).
          to receive(:flutter).
          with('build', 'ipa').
          and_yield(*successful_flutter(''))
        Fastlane::FastFile.new.parse(<<-FASTLANE).runner.execute(:test)
          default_platform(:ios)
          lane :test do
            flutter_build
          end
        FASTLANE
      end

      it 'embeds build_args' do
        expect(Fastlane::Helper::FlutterHelper).
          to receive(:flutter).
          with('build', 'apk', '--debug', '--split-per-abi').
          and_yield(*successful_flutter(''))
        Fastlane::FastFile.new.parse(<<-FASTLANE).runner.execute(:test)
          lane :test do
            flutter_build(build: 'apk', build_args: %w(--debug --split-per-abi))
          end
        FASTLANE
      end
    end

    describe 'gym environment' do
      it 'parses "-flavor ..." into GYM_SCHEME' do
        expect(Fastlane::Helper::FlutterHelper).
          to receive(:flutter).
          and_yield(*successful_flutter(''))
        Fastlane::FastFile.new.parse(<<-FASTLANE).runner.execute(:test)
          default_platform(:ios)
          lane :test do
            flutter_build(build_args: %w(-flavor paidApp))
          end
        FASTLANE
        expect(ENV['GYM_SCHEME']).to eq('paidApp')
      end

      it 'parses "--flavor=..." into GYM_SCHEME' do
        expect(Fastlane::Helper::FlutterHelper).
          to receive(:flutter).
          and_yield(*successful_flutter(''))
        Fastlane::FastFile.new.parse(<<-FASTLANE).runner.execute(:test)
          default_platform(:ios)
          lane :test do
            flutter_build(build_args: %w(--flavor=freeApp))
          end
        FASTLANE
        expect(ENV['GYM_SCHEME']).to eq('freeApp')
      end
    end
  end
end
