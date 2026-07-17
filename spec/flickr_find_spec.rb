describe "flickr_find" do
  let(:binary) { Pathname(__dir__)+"../bin/flickr_find" }

  it "opens browser with proper search" do
    MockUnix.new do |env|
      env.mock_command "open"
      env.mock_command "xdg-open"
      system "'#{binary}' 'kitten'"
      open_trace = env.command_trace("xdg-open") + env.command_trace("open")
      expect(open_trace).to eq([
        ["https://www.flickr.com/search/?text=kitten&license=1,2,3,4,5,6,9,11,12,13,14,15,16"],
      ])
    end
  end
end
