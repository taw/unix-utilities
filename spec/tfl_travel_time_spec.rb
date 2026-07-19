describe "tfl_travel_time" do
  let(:binary) { Pathname(__dir__)+"../bin/tfl_travel_time" }
  let(:angel) { "EC1V 1NE" }
  let(:waterstones) { "W1J 9HD" }

  def tfl_travel_time(*args)
    IO.popen(["ruby", "-r#{__dir__}/mock_network", binary.to_s, *args], &:read)
  end

  it "can tell travel time" do
    expect(tfl_travel_time(angel, waterstones)).to match(/\A\d{2,3}\n\z/)
  end
end
