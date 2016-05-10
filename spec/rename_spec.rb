describe "rename" do
  let(:binary) { Pathname(__dir__)+"../bin/rename" }

  it "renames files based on perl script passed as argument" do
    Dir.chtmpdir do |path|
      FileUtils.touch "one.txt"
      FileUtils.touch "two.txt"
      FileUtils.touch "three.md"
      FileUtils.touch "tfour.txt"
      system "'#{binary}' 's/txt/html/' t*"
      expect(path.descendants).to match_array([
        "one.txt",
        "tfour.html",
        "three.md",
        "two.html",
      ])
    end
  end
end
