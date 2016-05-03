describe "json_pp" do
  let(:binary) { Pathname(__dir__)+"../bin/json_pp" }

  it "prettyprints json" do
    IO.popen("#{binary}", "r+") do |fh|
      fh.puts '{"a":[1,2,3],"b":"foo","c":{"d":"e"}}'
      fh.close_write
      expect(fh.read).to eq(
'{
  "a": [
    1,
    2,
    3
  ],
  "b": "foo",
  "c": {
    "d": "e"
  }
}
')
    end
  end
end
