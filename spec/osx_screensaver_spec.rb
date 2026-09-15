describe "osx_screensaver" do
  let(:binary) { Pathname(__dir__)+"../bin/osx_screensaver" }

  def osx?
    RbConfig::CONFIG["host_os"] =~ /darwin/i
  end

  it "opens ScreenSaverEngine.app" do
    skip unless osx?

    MockUnix.new do |env|
      env.mock_command "open"
      status = system binary.to_s
      expect(status).to eq(true)
      trace = env.command_trace("open")
      expect(trace.size).to eq(1)
      expect(trace.first.first).to end_with("ScreenSaverEngine.app")
    end
  end

  it "fails when open fails" do
    skip unless osx?

    MockUnix.new do |env|
      env.mock_command "open", exit_status: 1
      status = system binary.to_s
      expect(status).to eq(false)
    end
  end
end
