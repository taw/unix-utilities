describe "osx_suspend" do
  let(:binary) { Pathname(__dir__)+"../bin/osx_suspend" }

  it "sleeps the machine via pmset" do
    MockUnix.new do |env|
      env.mock_command "pmset"
      status = system binary.to_s
      expect(status).to eq(true)
      expect(env.command_trace("pmset")).to eq([
        ["sleepnow"],
      ])
    end
  end

  it "fails when pmset fails" do
    MockUnix.new do |env|
      env.mock_command "pmset", exit_status: 1
      status = system binary.to_s
      expect(status).to eq(false)
    end
  end
end
