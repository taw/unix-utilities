describe "tfl_travel_time" do
  let(:binary) { Pathname(__dir__)+"../bin/tfl_travel_time" }
  let(:angel) { "EC1V 1NE" }
  let(:waterstones) { "W1J 9HD" }

  it "can tell travel time" do
    travel_time = `"#{binary}" "#{angel}" "#{waterstones}"`
    expect(travel_time).to match(/\A\d{2,3}\n\z/)
  end
end
