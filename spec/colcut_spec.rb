describe "colcut" do
  let(:binary) { Pathname(__dir__)+"../bin/colcut" }
  it "cuts columns to 120 characters by default" do
    IO.popen("#{binary}", "r+") do |fh|
      fh.puts "x" * 200
      fh.close_write
      expect(fh.read).to eq(
        "x" * 120 + "\n"
      )
    end
  end

  it "cuts columns to specified number of characters" do
    IO.popen("#{binary} 20", "r+") do |fh|
      fh.print "abc\n"
      fh.print ("a".."z").to_a.join + "\n"
      fh.print "abcde\n"
      fh.close_write
      expect(fh.read).to eq(
        "abc\n" +
        "abcdefghijklmnopqrst\n" +
        "abcde\n"
      )
    end
  end

  it "forces standard line endings" do
    IO.popen("#{binary}", "r+") do |fh|
      fh.print "x\r\n"
      fh.print "y\n"
      fh.print "z"

      fh.close_write
      expect(fh.read).to eq(
        "x\ny\nz\n"
      )
    end
  end
end
