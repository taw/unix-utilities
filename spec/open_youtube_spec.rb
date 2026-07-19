require "open3"

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

  it "accepts every character allowed in a Youtube ID" do
    MockUnix.new do |env|
      env.mock_command "open"
      system "#{binary}", "clip-aZ0_-zA9x_Q.mp4"
      expect(env.command_trace("open")).to eq([
        ["https://www.youtube.com/watch?v=aZ0_-zA9x_Q"],
      ])
    end
  end

  ["too short.mkv", "eleven chars.mkv", "name with spaces here.mkv", "clip+Yavx9yxTrs.mkv", ".mkv"].each do |bad_name|
    it "warns and continues for `#{bad_name}'" do
      MockUnix.new do |env|
        env.mock_command "open"
        _out, err, status = Open3.capture3(binary.to_s, bad_name, "boxxy-Yavx9yxTrsw.mkv")
        expect(err).to eq("No Youtube ID found in `#{bad_name}', skipping\n")
        expect(status).to be_success
        expect(env.command_trace("open")).to eq([
          ["https://www.youtube.com/watch?v=Yavx9yxTrsw"],
        ])
      end
    end
  end
end
