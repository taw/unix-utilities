describe "randsample" do
  let(:binary) { Pathname(__dir__)+"../bin/randsample" }

  it "gets one sample if no arguments passed" do
    results = 10.times.map{`seq 100 | #{binary}`}
    expect(results.map(&:lines).map(&:size)).to eq([1] * 10)
  end

  it "gets N samples if argument passed" do
    results = 10.times.map{`seq 100 | #{binary} 7`}
    expect(results.map(&:lines).map(&:size)).to eq([7] * 10)
  end
end
