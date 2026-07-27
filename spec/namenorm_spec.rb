describe "namenorm" do
  let(:binary) { Pathname(__dir__)+"../bin/namenorm" }

  it "normalizes file names" do
    MockUnix.new do |env|
      FileUtils.touch "KATY PERRY - ROAR.MP3"
      FileUtils.touch "ubuntu.14.04.iso.gz"
      FileUtils.touch "INDEX.HTM"
      FileUtils.touch "read me.txt"
      system "#{binary} *"
      expect(env).to have_content([
        "index.htm",
        "katy_perry_-_roar.mp3",
        "read_me.txt",
        "ubuntu.14.04.iso.gz",
      ])
    end
  end

  it "leaves directories leading to the file alone" do
    MockUnix.new do |env|
      FileUtils.mkdir_p "My Dir/Sub Dir"
      FileUtils.touch "My Dir/Sub Dir/Some File.TXT"
      system binary.to_s, "My Dir/Sub Dir/Some File.TXT"
      expect(env).to have_content([
        "My Dir",
        "My Dir/Sub Dir",
        "My Dir/Sub Dir/some_file.txt",
      ])
    end
  end

  it "normalizes directories passed to it directly" do
    MockUnix.new do |env|
      FileUtils.mkdir_p "Outer Dir/Inner Dir"
      FileUtils.touch "Outer Dir/Inner Dir/Keep This.TXT"
      system binary.to_s, "Outer Dir/Inner Dir"
      expect(env).to have_content([
        "Outer Dir",
        "Outer Dir/inner_dir",
        "Outer Dir/inner_dir/Keep This.TXT",
      ])
    end
  end
end
