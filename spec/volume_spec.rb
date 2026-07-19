describe "volume" do
  let(:binary) { Pathname(__dir__)+"../bin/volume" }

  it "prints current volume" do
    MockUnix.new do |env|
      env.mock_command "osascript"
      system "#{binary}"
      expect(env.command_trace("osascript")).to eq([
        ["-e", "output volume of (get volume settings)"],
      ])
    end
  end

  it "sets volume" do
    MockUnix.new do |env|
      env.mock_command "osascript"
      system "#{binary}", "42"
      expect(env.command_trace("osascript")).to eq([
        ["-e", "set volume output volume 42.0"],
      ])
    end
  end

  it "accepts floats, negative numbers, and numbers over 100" do
    MockUnix.new do |env|
      env.mock_command "osascript"
      system "#{binary}", "12.5"
      system "#{binary}", "-3"
      system "#{binary}", "1e3"
      expect(env.command_trace("osascript")).to eq([
        ["-e", "set volume output volume 12.5"],
        ["-e", "set volume output volume -3.0"],
        ["-e", "set volume output volume 1000.0"],
      ])
    end
  end

  it "refuses non-numbers" do
    MockUnix.new do |env|
      env.mock_command "osascript"
      expect(`#{binary} loud 2>&1`).to eq("Volume must be a number, got: loud\n")
      expect($?.exitstatus).to eq(1)
      expect(env.command_trace("osascript")).to eq([])
    end
  end

  it "refuses empty argument" do
    MockUnix.new do |env|
      env.mock_command "osascript"
      expect(`#{binary} '' 2>&1`).to eq("Volume must be a number, got: \n")
      expect($?.exitstatus).to eq(1)
      expect(env.command_trace("osascript")).to eq([])
    end
  end

  it "prints usage for too many arguments" do
    MockUnix.new do |env|
      env.mock_command "osascript"
      expect(`#{binary} 10 20 2>&1`).to include("Usage:")
      expect($?.exitstatus).to eq(1)
      expect(env.command_trace("osascript")).to eq([])
    end
  end
end
