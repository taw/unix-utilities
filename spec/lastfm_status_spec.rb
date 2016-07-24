describe "lastfm_status" do
  let(:binary) { Pathname(__dir__)+"../bin/lastfm_status" }

  # Something old and abandoned or close enough
  it "real account" do
    expect(`#{binary} niphree`).to match(
      /\Aniphree's last song was `Master of Tides' by `Lindsey Stirling` at 2015-05-13 05:45:00 \+0100\nIt was \d+d \d+h \d+m\d+s ago\n\z/
    )
  end

  it "bad account" do
    expect(`#{binary} no_such_username`).to eq("No recent songs by no_such_username\n")
  end
end
