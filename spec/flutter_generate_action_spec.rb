# frozen_string_literal: true

describe Fastlane::Actions::FlutterGenerateAction do
  describe '#run' do
    before do
      expect(Fastlane::Helper::FlutterHelper)
        .to receive(:flutter)
        .with('packages', 'get')
    end

    it 'just passes when there are no known flags' do
      expect(Fastlane::Helper::FlutterHelper)
        .to receive(:dev_dependency?)
        .with('intl_translation').
        # Once for verifying arguments, once for running the action.
        twice
        .and_return(false)

      expect(Fastlane::Helper::FlutterHelper)
        .to receive(:dev_dependency?)
        .with('build_runner')
        .and_return(false)

      Fastlane::FastFile.new.parse(<<-FASTLANE).runner.execute(:test)
        lane :test do
          flutter_generate()
        end
      FASTLANE
    end

    describe 'coverage_all_imports' do
      before do
        expect(Fastlane::Helper::FlutterHelper)
          .to receive(:dev_dependency?)
          .with('intl_translation').
          # Once for verifying arguments, once for running the action.
          twice
          .and_return(false)
        expect(Fastlane::Helper::FlutterHelper)
          .to receive(:dev_dependency?)
          .with('build_runner')
          .and_return(false)
      end

      it 'generates the file' do
        expect(Dir)
          .to receive(:[])
          .with('lib/**/*.dart')
          .and_return(
            %w[
              lib/main.dart
              lib/bad_imports.dart
              lib/built_list_of_things.g.dart
            ]
          )
        expect(Fastlane::Helper::FlutterHelper)
          .to receive(:pub_package_name)
          .at_least(:once)
          .and_return('my_package')
        expect(File)
          .to receive(:read)
          .with('lib/main.dart', 4096)
          .and_return(<<-DART)
            import 'package:my_package/bad_imports.dart';
            void main() {}
          DART
        expect(File)
          .to receive(:read)
          .with('lib/bad_imports.dart', 4096)
          .and_return(<<-DART)
            import './main.dart';
          DART
        expect(File)
          .to receive(:write)
          .with('test/all_imports_for_coverage_test.dart', include(<<~DART))
            import '../lib/bad_imports.dart';
            import 'package:my_package/main.dart';

            void main() {}
          DART

        Fastlane::FastFile.new.parse(<<-FASTLANE).runner.execute(:test)
          lane :test do
            flutter_generate(coverage_all_imports: true)
          end
        FASTLANE
      end
    end
  end
end
