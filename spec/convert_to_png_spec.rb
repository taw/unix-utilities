describe "convert_to_png" do
  let(:binary) { Pathname(__dir__)+"../bin/convert_to_png" }

  it "converts every file to a png next to it" do
    MockUnix.new do |env|
      env.mock_command "convert"
      (env.path+"cat.jpg").write("")
      (env.path+"dog.gif").write("")
      system binary.to_s, "cat.jpg", "dog.gif"
      expect(env.command_trace("convert")).to eq([
        ["cat.jpg", "cat.png"],
        ["dog.gif", "dog.png"],
      ])
    end
  end

  it "converts files with upper case extensions" do
    MockUnix.new do |env|
      env.mock_command "convert"
      (env.path+"cat.JPG").write("")
      (env.path+"dog.Gif").write("")
      system binary.to_s, "cat.JPG", "dog.Gif"
      expect(env.command_trace("convert")).to eq([
        ["cat.JPG", "cat.png"],
        ["dog.Gif", "dog.png"],
      ])
    end
  end

  it "skips files which are png already, whatever the case" do
    MockUnix.new do |env|
      env.mock_command "convert"
      (env.path+"cat.png").write("")
      (env.path+"dog.PNG").write("")
      system binary.to_s, "cat.png", "dog.PNG"
      expect(env.command_trace("convert")).to eq([])
    end
  end

  it "doesn't overwrite existing png files" do
    MockUnix.new do |env|
      env.mock_command "convert"
      (env.path+"cat.jpg").write("")
      (env.path+"cat.png").write("")
      output = IO.popen([binary.to_s, "cat.jpg"], &:read)
      expect(output).to eq("Not converting cat.jpg to cat.png because target exists\n")
      expect(env.command_trace("convert")).to eq([])
    end
  end
end
