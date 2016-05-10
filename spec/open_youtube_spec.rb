describe "open_youtube" do
  let(:binary) { Pathname(__dir__)+"../bin/open_youtube" }

  it "opens URLs based on ID in file names passed" do
    MockUnix.new do |env|
      env.mock_command "open"
      system "#{binary}", "FOAR EVERYWUN FRUM BOXXY-Yavx9yxTrsw.mkv"
      expect(env.command_trace("open")).to eq([
        ["https://www.youtube.com/watch?v=Yavx9yxTrsw"],
      ])
    end
  end
end
