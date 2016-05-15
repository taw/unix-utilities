describe "openmany" do
  let(:binary) { Pathname(__dir__)+"../bin/openmany" }

  it "opens files listed on command line" do
    MockUnix.new do |env|
      env.mock_command "open"
      system "#{binary} a b c"
      open_trace = env.command_trace("xdg-open") + env.command_trace("open")
      expect(open_trace).to eq([
        ["a"],
        ["b"],
        ["c"],
      ])
    end
  end

  it "opens files listed from STDIN if no command line arguments are passed" do
    MockUnix.new do |env|
      env.mock_command "open"
      IO.popen("#{binary}", "r+") do |fh|
        fh.puts "d"
        fh.puts "e"
        fh.puts "f"
        fh.close_write
      end
      open_trace = env.command_trace("xdg-open") + env.command_trace("open")
      expect(open_trace).to eq([
        ["d"],
        ["e"],
        ["f"],
      ])
    end
  end
end
