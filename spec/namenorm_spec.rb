describe "namenorm" do
  let(:binary) { Pathname(__dir__)+"../bin/namenorm" }

  it "normalizes file names" do
    MockUnix.new do |env|
      FileUtils.touch "KATY PERRY - ROAR.MP3"
      FileUtils.touch "ubuntu.14.04.iso.gz"
      FileUtils.touch "INDEX.HTM"
      FileUtils.touch "read me.txt"
      system "namenorm *"
      expect(env).to have_content([
        "index.htm",
        "katy_perry_-_roar.mp3",
        "read_me.txt",
        "ubuntu.14.04.iso.gz",
      ])
    end
  end
end
