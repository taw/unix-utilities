describe "xrmdir" do
  let(:binary) { Pathname(__dir__)+"../bin/xrmdir" }

  it "removes empty directories, killing .DS_Store on the way" do
    MockUnix.new do |env|
      FileUtils.mkdir_p "one"
      FileUtils.mkdir_p "two"
      FileUtils.mkdir_p "three/four"
      FileUtils.mkdir_p "three/five"
      FileUtils.touch "two/.DS_Store"
      FileUtils.touch "three/five/.DS_Store"
      system "#{binary} *"
      expect(env).to have_content([
        "three",
        "three/five",
        "three/five/.DS_Store",
        "three/four",
      ])
    end
  end

  it "recursively removes empty directories, killing .DS_Store on the way" do
    MockUnix.new do |env|
      FileUtils.mkdir_p "one"
      FileUtils.mkdir_p "two"
      FileUtils.mkdir_p "three/four"
      FileUtils.mkdir_p "three/five"
      FileUtils.mkdir_p "six/seven"
      FileUtils.mkdir_p "six/eight"
      FileUtils.touch "two/.DS_Store"
      FileUtils.touch "three/five/.DS_Store"
      FileUtils.touch "six/eight/nine.txt"
      system "#{binary} -r *"
      expect(env).to have_content([
        "six",
        "six/eight",
        "six/eight/nine.txt",
      ])
    end
  end
end
