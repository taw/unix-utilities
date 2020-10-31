
describe "gzip_stream" do
  # To verify that plain gzip doesn't work for it:
  # let(:binary) { "gzip" }
  let(:binary) { Pathname(__dir__)+"../bin/gzip_stream" }
  it "gzips" do
    IO.popen("#{binary} | zcat", "r+") do |fh|
      fh.puts *(1..1000)
      fh.close_write
      expect(fh.readlines).to eq((1..1000).map{|x| "#{x}\n"})
    end
  end

  it "doesn't wait for end of input" do
    IO.popen("#{binary}", "r+") do |fh|
      fh.puts *(1..1000)
      sleep 2
      a = fh.read_nonblock(10_000)
      fh.close_write
      b = fh.read
      # Data
      expect(a.size).to be_between(1750, 1900)
      # Just finalization mark
      expect(b.size).to eq(9)
    end
  end
end
