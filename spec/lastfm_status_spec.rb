describe "lastfm_status" do
  let(:binary) { Pathname(__dir__)+"../bin/lastfm_status" }

  # Something old and abandoned or close enough
  # timezone last.fm returns doesn't seem to be consistent
  it "real account" do
    expect(`#{binary} niphree`).to match(
      /\Aniphree's last song was `Master of Tides' by `Lindsey Stirling' at 2015-05-13 \d+:45:00 \+\d{4}\nIt was \d+d \d+h \d+m\d+s ago\n\z/
    )
  end

  it "bad account" do
    expect(`#{binary} no_such_username`).to eq("No recent songs by no_such_username\n")
  end
end
