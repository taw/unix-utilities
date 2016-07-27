describe "countdown" do
  let(:binary) { Pathname(__dir__)+"../bin/countdown" }

  it "counts down, then runs specified command" do
    IO.popen("#{binary} 5 echo Done", "r+") do |fh|
      expect(fh.read).to eq([
        "\r0:05",
        "\r0:04",
        "\r0:03",
        "\r0:02",
        "\r0:01",
        "\r0:00",
        "\rSTART!\n",
        "Done\n",
      ].join)
    end
  end
end
