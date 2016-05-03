describe "tac" do
  let(:binary) { Pathname(__dir__)+"../bin/tac" }

  it "prints lines in reverse" do
    IO.popen("#{binary}", "r+") do |fh|
      fh.print "a\nb\nc\n"
      fh.close_write
      expect(fh.read).to eq("c\nb\na\n")
    end
  end

  it "normalizes newlines" do
    IO.popen("#{binary}", "r+") do |fh|
      fh.print "a\r\nb\nc"
      fh.close_write
      expect(fh.read).to eq("c\nb\na\n")
    end
  end
end
