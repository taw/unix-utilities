describe "progress" do
  let(:binary) { Pathname(__dir__)+"../bin/progress" }

  def run(*args, input:)
    Open3.capture3(binary.to_s, *args, stdin_data: input)
  end

  it "passes stdin through to stdout unchanged" do
    out, _, status = run(input: "hello world")
    expect(out).to eq("hello world")
    expect(status).to be_success
  end

  it "passes through input larger than a single read chunk" do
    data = "x" * 20_000
    out, _, status = run(input: data)
    expect(out).to eq(data)
    expect(status).to be_success
  end

  it "counts lines instead of bytes with -l" do
    out, _, status = run("-l", input: "a\nb\nc\n")
    expect(out).to eq("a\nb\nc\n")
    expect(status).to be_success
  end

  it "accepts a byte limit with k/m/g suffixes" do
    # With a limit far bigger than the input, the percentage is 0% no matter
    # how many times the progress thread happens to have sampled the count.
    _, err, status = run("1m", input: "hi")
    expect(status).to be_success
    expect(err).to match(%r{/1048576 \[0%\]})
  end

  it "defaults the byte limit to the input file's size when reading a real file" do
    Dir.mktmpdir do |dir|
      path = Pathname(dir)+"input.dat"
      path.write("x" * 100)
      out, err, status = Open3.capture3("#{binary} < #{path}")
      expect(out).to eq("x" * 100)
      expect(status).to be_success
      expect(err).to match(%r{/100 \[\d+%\]})
    end
  end

  it "rejects unrecognized arguments" do
    _, err, status = run("--bogus", input: "hi")
    expect(err).to include("Unrecognized argument: `--bogus'")
    expect(status.exitstatus).to eq(1)
  end
end
