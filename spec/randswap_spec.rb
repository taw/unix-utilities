describe "randswap" do
  let(:binary) { Pathname(__dir__)+"../bin/randswap" }

  it "generates random permutations" do
    permutations = 10.times.map{`seq 100 | #{binary}`}
    expect(permutations.size).to eq(permutations.uniq.size)
    permutations.each do |permutation|
      expect(permutation.lines.sort_by(&:to_i)).to eq (1..100).map{|i| "#{i}\n"}
    end
  end

  it "normalizes newlines" do
    IO.popen("#{binary}", "r+") do |fh|
      fh.print "a\r\nb\nc"
      fh.close_write
      expect(fh.read.lines.sort).to eq(["a\n", "b\n", "c\n"])
    end
  end
end
