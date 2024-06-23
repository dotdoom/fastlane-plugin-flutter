# frozen_string_literal: true

require 'climate_control'

describe Fastlane::Actions::FlutterBootstrapAction do
  describe '#run' do
    describe 'android_licenses' do
      it 'Fails when Android licenses are specified but no SDK path' do
        ClimateControl.modify(ANDROID_HOME: nil, ANDROID_SDK_ROOT: nil) do
          expect do
            Fastlane::FastFile.new.parse(<<-FASTLANE).runner.execute(:test)
              lane :test do
                flutter_bootstrap(
                  android_licenses: {
                    sdk: 'abcdef',
                  },
                )
              end
            FASTLANE
          end.to raise_error(FastlaneCore::Interface::FastlaneBuildFailure)
        end
      end

      it 'Installs Android licenses when specified' do
        ClimateControl.modify(
          ANDROID_HOME: nil,
          ANDROID_SDK_ROOT: '/tmp/android_sdk_root'
        ) do
          expect(Fastlane::Helper::FlutterBootstrapHelper)
            .to receive(:accept_licenses)
            .with('/tmp/android_sdk_root/licenses', { sdk: 'abcdef' })

          expect(Fastlane::Helper::FlutterHelper)
            .to receive(:flutter_installed?)
            .and_return(true)
          expect(Fastlane::Helper::FlutterHelper)
            .to receive(:flutter_sdk_root)
            .and_return('/tmp/flutter')

          Fastlane::FastFile.new.parse(<<-FASTLANE).runner.execute(:test)
            lane :test do
              flutter_bootstrap(
                flutter_auto_upgrade: false,
                android_licenses: {
                  sdk: 'abcdef',
                },
              )
            end
          FASTLANE
        end
      end
    end

    describe 'flutter_...' do
      before do
        expect(Fastlane::Helper::FlutterHelper)
          .to receive(:flutter_sdk_root)
          .and_return('/tmp/flutter')
      end

      it 'Returns SDK path when Flutter is installed and no updates asked' do
        expect(Fastlane::Helper::FlutterHelper)
          .to receive(:flutter_installed?)
          .and_return(true)

        path = Fastlane::FastFile.new.parse(<<-FASTLANE).runner.execute(:test)
          lane :test do
            flutter_bootstrap(flutter_auto_upgrade: false)
          end
        FASTLANE

        expect(path).to eq('/tmp/flutter')
      end
    end
  end
end
