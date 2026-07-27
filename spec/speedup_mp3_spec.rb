describe "speedup_mp3" do
  let(:binary) { Pathname(__dir__)+"../bin/speedup_mp3" }
  let(:filter) { "[0:v]setpts=PTS/1.4[v];[0:a]atempo=1.4[a]" }

  def speedup_mp3(*args)
    system binary.to_s, *args, err: File::NULL
  end

  it "speeds up video files with ffmpeg" do
    MockUnix.new do |env|
      env.mock_command "ffmpeg"
      (env.path+"in.mp4").write("")
      expect(speedup_mp3("in.mp4", "out.mp4")).to eq(true)
      expect(env.command_trace("ffmpeg")).to eq([
        ["-i", "in.mp4", "-filter_complex", filter, "-map", "[v]", "-map", "[a]", "part-out.mp4"],
      ])
      expect(env).to have_content(["in.mp4", "out.mp4"])
    end
  end

  # Otherwise the timestamp copying creates the missing part file, and it gets
  # renamed into an empty file which looks just like a successful conversion
  it "doesn't leave an empty target behind when ffmpeg fails" do
    MockUnix.new do |env|
      env.mock_command "ffmpeg", exit_status: 1
      (env.path+"in.mp4").write("")
      expect(speedup_mp3("in.mp4", "out.mp4")).to eq(false)
      expect(env).to have_content(["in.mp4"])
    end
  end
end
