describe "rjq" do
  let(:binary) { Pathname(__dir__)+"../bin/rjq" }

  it "rjq process and pretty-print" do
    IO.popen("#{binary} '$_=$_.map(&:abs)'", "r+") do |fh|
      fh.puts "[-1,2,-3,4]"
      fh.close_write
      expect(fh.read).to eq(
        "[\n"+
        "  1,\n"+
        "  2,\n"+
        "  3,\n"+
        "  4\n"+
        "]\n"
      )
    end
  end
end
