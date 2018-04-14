describe Fastlane::Actions::FlutterAction do
  describe '#run:format' do
    it 'runs a "flutter format" command' do
      expect(Fastlane::Actions::FlutterAction).to receive(:sh).
        with('flutter', 'format', 'lib')

      Fastlane::Actions::FlutterAction.run(action: 'format', lib_path: 'lib')
    end
  end
end
