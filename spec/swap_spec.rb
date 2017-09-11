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
end
