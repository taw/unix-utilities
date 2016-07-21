describe "sortby" do
  let(:binary) { Pathname(__dir__)+"../bin/sortby" }

  it "sortby abs" do
    IO.popen("#{binary} '$_.to_i.abs'", "r+") do |fh|
      fh.puts "12"
      fh.puts "-91"
      fh.puts "34"
      fh.puts "-17"
      fh.close_write
      expect(fh.read).to eq(
        "12\n"+
        "-17\n"+
        "34\n"+
        "-91\n"
      )
    end
  end

  it "sortby size" do
    IO.popen("#{binary} '[$_.size, $_]'", "r+") do |fh|
      fh.puts %W[Lorem ipsum dolor sit amet, consectetur adipisicing elit]
      fh.close_write
      expect(fh.read.tr("\n", " ")).to eq(
        "sit elit Lorem amet, dolor ipsum adipisicing consectetur "
      )
    end
  end
end
