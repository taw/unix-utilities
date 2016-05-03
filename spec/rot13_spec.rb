describe "rot13" do
  let(:binary) { Pathname(__dir__)+"../bin/rot13" }

  it "reads from STDIN if used without arguments" do
    IO.popen("#{binary}", "r+") do |fh|
      fh.print "Lorem ipsum dolor sit amet, consectetur adipisicing elit\n"
      fh.close_write
      expect(fh.read).to eq("Yberz vcfhz qbybe fvg nzrg, pbafrpgrghe nqvcvfvpvat ryvg\n")
    end
  end

  it "doesn't affect end of lines" do
    IO.popen("#{binary}", "r+") do |fh|
      fh.print "a\r\nb\nc"
      fh.close_write
      expect(fh.read).to eq("n\r\no\np")
    end
  end
end
