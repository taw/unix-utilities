# bin/countdown only counts down when executed directly, so loading it here
# just defines the helpers, and we can test them without waiting minutes
load Pathname(__dir__)+"../bin/countdown"

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

  describe "fmt_time" do
    it "formats minutes and seconds" do
      expect([601, 600, 599, 60, 5, 0].map{|s| fmt_time(s)}).to eq(
        ["10:01", "10:00", "9:59", "1:00", "0:05", "0:00"]
      )
    end

    it "clamps overshoot to zero instead of printing negative times" do
      expect(fmt_time(-1)).to eq("0:00")
    end
  end

  describe "status_printer" do
    let(:io) { StringIO.new }
    let(:print_status) { status_printer(io) }

    it "pads shorter statuses, so nothing stale is left on the line" do
      ["10:01", "10:00", "9:59", "1:00"].each{|s| print_status[s]}
      expect(io.string).to eq("\r10:01\r10:00\r9:59 \r1:00 ")
    end

    it "doesn't pad when the width never shrinks" do
      ["0:05", "0:04", "START!"].each{|s| print_status[s]}
      expect(io.string).to eq("\r0:05\r0:04\rSTART!")
    end
  end
end
