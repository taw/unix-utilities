require "mp3info"

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

  # sox drops ID3 tags, so the mock produces an untagged mp3 in its place
  it "speeds up mp3 files with sox, keeping their tags" do
    MockUnix.new do |env|
      untagged = Pathname(__dir__)+"speedup_mp3/untagged.mp3"
      env.mock_command "sox", script: "require 'fileutils'; FileUtils.cp(#{untagged.to_s.inspect}, ARGV[3])"
      FileUtils.cp Pathname(__dir__)+"speedup_mp3/tagged.mp3", "in.mp3"
      expect(speedup_mp3("in.mp3", "out.mp3")).to eq(true)
      expect(env.command_trace("sox")).to eq([
        ["in.mp3", "-t", "mp3", "out.mp3.part", "tempo", "-s", "1.4"],
      ])
      expect(env).to have_content(["in.mp3", "out.mp3"])
      expect(Mp3Info.open("out.mp3"){|mp3| mp3.tag2.to_h}).to eq({
        "TIT2" => "Zażółć gęślą jaźń",
        "TPE1" => "Some Author",
        "TALB" => "Some Album",
        "TYER" => "2009",
        "TCON" => "Podcast",
        "COMM" => "Episode notes",
      })
    end
  end

  it "converts untagged mp3 files" do
    MockUnix.new do |env|
      untagged = Pathname(__dir__)+"speedup_mp3/untagged.mp3"
      env.mock_command "sox", script: "require 'fileutils'; FileUtils.cp(#{untagged.to_s.inspect}, ARGV[3])"
      FileUtils.cp untagged, "in.mp3"
      expect(speedup_mp3("in.mp3", "out.mp3")).to eq(true)
      expect(Pathname("out.mp3").read).to eq(untagged.read)
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
