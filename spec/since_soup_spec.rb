describe "since_soup" do
  let(:binary) { Pathname(__dir__)+"../bin/since_soup" }

  it "reads from ARGV if used with arguments" do
    IO.popen("#{binary} http://taw.soup.io/post/307955954/Image", "r+") do |fh|
      fh.close_write
      expect(fh.read).to eq("http://taw.soup.io/since/307955954\n")
    end    
  end

  it "reads from STDIN if used without arguments" do
    IO.popen("#{binary}", "r+") do |fh|
      fh.print "http://taw.soup.io/post/307955954/Image\n"
      fh.close_write
      expect(fh.read).to eq("http://taw.soup.io/since/307955954\n")
    end
  end
end
