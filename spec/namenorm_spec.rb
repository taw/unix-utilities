describe "namenorm" do
  let(:binary) { Pathname(__dir__)+"../bin/namenorm" }

  it "normalizes file names" do
    Dir.chtmpdir do |path|
      FileUtils.touch "KATY PERRY - ROAR.MP3"
      FileUtils.touch "ubuntu.14.04.iso.gz"
      FileUtils.touch "INDEX.HTM"
      FileUtils.touch "read me.txt"
      system "namenorm *"
      expect( path.find.map{|x| x.relative_path_from(path).to_s} ).to match_array([
        ".",
        "index.htm",
        "katy_perry_-_roar.mp3",
        "read_me.txt",
        "ubuntu.14.04.iso.gz",
      ])
    end
  end
end
