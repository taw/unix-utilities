describe "open_chrome" do
  let(:binary) { Pathname(__dir__)+"../bin/open_chrome" }

  it "opens urls listed on command line" do
    MockUnix.new do |env|
      env.mock_command "open"
      system binary.to_s, "http://a.example/", "http://b.example/"
      expect(env.command_trace("open")).to eq([
        ["-na", "Google Chrome", "http://a.example/", "http://b.example/"],
      ])
    end
  end

  it "opens urls from STDIN if no command line arguments are passed" do
    MockUnix.new do |env|
      env.mock_command "open"
      IO.popen([binary.to_s], "r+") do |fh|
        fh.puts "http://a.example/"
        fh.puts ""
        fh.puts "http://b.example/"
        fh.close_write
      end
      expect(env.command_trace("open")).to eq([
        ["-na", "Google Chrome", "http://a.example/", "http://b.example/"],
      ])
    end
  end
end
