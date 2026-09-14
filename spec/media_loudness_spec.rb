describe "media_loudness" do
  let(:binary) { Pathname(__dir__)+"../bin/media_loudness" }

  def media_loudness(*args)
    Open3.capture3(binary.to_s, *args)
  end

  it "prints the integrated loudness of a file" do
    MockUnix.new do |env|
      env.mock_command "ffmpeg", stdout: "Input Integrated:   -14.2 LUFS\n"
      Pathname("chapter.mp3").write("")
      out, err, status = media_loudness("chapter.mp3")
      expect(out).to eq("chapter.mp3: -14.2 LUFS\n")
      expect(err).to eq("")
      expect(status).to be_success
      expect(env.command_trace("ffmpeg")).to eq([
        ["-hide_banner", "-i", "chapter.mp3", "-af", "loudnorm=print_format=summary", "-f", "null", "-"],
      ])
    end
  end

  it "processes multiple files, in order" do
    MockUnix.new do |env|
      env.mock_command "ffmpeg", stdout: "Input Integrated:   -20.0 LUFS\n"
      Pathname("a.mp3").write("")
      Pathname("b.mp3").write("")
      out, _, status = media_loudness("a.mp3", "b.mp3")
      expect(out).to eq("a.mp3: -20.0 LUFS\nb.mp3: -20.0 LUFS\n")
      expect(status).to be_success
      expect(env.command_trace("ffmpeg").size).to eq(2)
    end
  end

  it "reports a missing file as N/A without aborting the rest of the batch" do
    MockUnix.new do |env|
      env.mock_command "ffmpeg", stdout: "Input Integrated:   -14.2 LUFS\n"
      Pathname("real.mp3").write("")
      out, err, status = media_loudness("missing.mp3", "real.mp3")
      expect(out).to eq("missing.mp3: N/A\nreal.mp3: -14.2 LUFS\n")
      expect(err).to eq("missing.mp3: file not found, skipping\n")
      expect(status).to be_success
      expect(env.command_trace("ffmpeg")).to eq([
        ["-hide_banner", "-i", "real.mp3", "-af", "loudnorm=print_format=summary", "-f", "null", "-"],
      ])
    end
  end

  it "reports N/A when ffmpeg's output can't be parsed" do
    MockUnix.new do |env|
      env.mock_command "ffmpeg", stdout: "no useful output here\n"
      Pathname("chapter.mp3").write("")
      out, err, status = media_loudness("chapter.mp3")
      expect(out).to eq("chapter.mp3: N/A\n")
      expect(err).to eq("chapter.mp3: could not parse loudness (ffmpeg ran but no match found)\n")
      expect(status).to be_success
    end
  end

  it "prints usage and fails when called without arguments" do
    MockUnix.new do
      out, _, status = media_loudness
      expect(out).to include("Usage:")
      expect(status.exitstatus).to eq(1)
    end
  end

  it "prints usage and succeeds for --help" do
    MockUnix.new do
      out, _, status = media_loudness("--help")
      expect(out).to include("Usage:")
      expect(status).to be_success
    end
  end
end
