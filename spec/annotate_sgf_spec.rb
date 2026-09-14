describe "annotate_sgf" do
  let(:binary) { Pathname(__dir__)+"../bin/annotate_sgf" }

  def annotate_sgf(*args)
    Open3.capture3(binary.to_s, *args)
  end

  it "annotates games with gnugo, writing alongside each input file" do
    MockUnix.new do |env|
      env.mock_command "gnugo"
      Pathname("game.sgf").write("(;)")
      Pathname("dir").mkpath
      Pathname("dir/other.sgf").write("(;)")

      _, err, status = annotate_sgf("game.sgf", "dir/other.sgf")
      expect(err).to eq("")
      expect(status).to be_success
      expect(env.command_trace("gnugo")).to eq([
        ["--level", "15", "--output-flags", "dv", "--replay", "both", "-l", "game.sgf", "-o", "./annotated-game.sgf"],
        ["--level", "15", "--output-flags", "dv", "--replay", "both", "-l", "dir/other.sgf", "-o", "dir/annotated-other.sgf"],
      ])
    end
  end

  it "does nothing, and doesn't require gnugo, when given no files" do
    MockUnix.new do
      _, err, status = annotate_sgf
      expect(err).to eq("")
      expect(status).to be_success
    end
  end

  it "fails with a clear message when gnugo isn't installed" do
    MockUnix.new do
      Pathname("game.sgf").write("(;)")
      _, err, status = annotate_sgf("game.sgf")
      expect(err).to include("requires gnugo")
      expect(status.exitstatus).to eq(1)
    end
  end
end
