describe "rename" do
  let(:binary) { Pathname(__dir__)+"../bin/rename" }

  it "renames files based on perl script passed as argument" do
    MockUnix.new do |env|
      FileUtils.touch "one.txt"
      FileUtils.touch "two.txt"
      FileUtils.touch "three.md"
      FileUtils.touch "tfour.txt"
      system "'#{binary}' 's/txt/html/' t*"
      expect(env).to have_content([
        "one.txt",
        "tfour.html",
        "three.md",
        "two.html",
      ])
    end
  end
end
