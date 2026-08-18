describe "swap" do
  let(:binary) { Pathname(__dir__)+"../bin/swap" }

  it "swaps 2 files" do
    MockUnix.new do |env|
      Pathname("one.txt").write("1")
      Pathname("two.txt").write("2")
      system "#{binary}", "one.txt", "two.txt"
      expect(env).to have_content([
        "one.txt",
        "two.txt",
      ])
      expect(Pathname("one.txt").read).to eq("2")
      expect(Pathname("two.txt").read).to eq("1")
    end
  end

  it "swaps symlinks as symlinks, without touching their targets" do
    MockUnix.new do |env|
      Pathname("one.txt").write("1")
      Pathname("two.txt").write("2")
      Pathname("one").make_symlink("one.txt")
      Pathname("two").make_symlink("two.txt")
      system "#{binary}", "one", "two"
      expect(Pathname("one").readlink.to_s).to eq("two.txt")
      expect(Pathname("two").readlink.to_s).to eq("one.txt")
      expect(Pathname("one.txt").read).to eq("1")
      expect(Pathname("two.txt").read).to eq("2")
    end
  end

  it "swaps broken symlinks" do
    MockUnix.new do |env|
      Pathname("data.txt").write("1")
      Pathname("broken").make_symlink("nosuchfile")
      system "#{binary}", "broken", "data.txt"
      expect(env).to have_content([
        "broken",
        "data.txt",
      ])
      expect(Pathname("broken").read).to eq("1")
      expect(Pathname("data.txt").readlink.to_s).to eq("nosuchfile")
    end
  end

  it "swaps more than 2 files" do
    MockUnix.new do |env|
      Pathname("one.txt").write("1")
      Pathname("two.txt").write("2")
      Pathname("three.txt").write("3")
      Pathname("four.txt").write("4")
      system "#{binary}", "one.txt", "two.txt", "three.txt", "four.txt"
      expect(env).to have_content([
        "one.txt",
        "two.txt",
        "three.txt",
        "four.txt",
      ])
      expect(Pathname("one.txt").read).to eq("4")
      expect(Pathname("two.txt").read).to eq("1")
      expect(Pathname("three.txt").read).to eq("2")
      expect(Pathname("four.txt").read).to eq("3")
    end
  end

  it "swaps more than 2 paths when some of them are broken symlinks" do
    MockUnix.new do |env|
      Pathname("one.txt").write("1")
      Pathname("broken").make_symlink("nosuchfile")
      Pathname("three.txt").write("3")
      system "#{binary}", "one.txt", "broken", "three.txt"
      expect(env).to have_content([
        "one.txt",
        "broken",
        "three.txt",
      ])
      expect(Pathname("one.txt").read).to eq("3")
      expect(Pathname("broken").read).to eq("1")
      expect(Pathname("three.txt").readlink.to_s).to eq("nosuchfile")
    end
  end
end
