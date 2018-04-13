describe Fastlane::Actions::FlutterAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The flutter plugin is working!")

      Fastlane::Actions::FlutterAction.run(nil)
    end
  end
end
