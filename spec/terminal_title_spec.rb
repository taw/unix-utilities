describe "terminal_title" do
  let(:binary) { Pathname(__dir__)+"../bin/terminal_title" }

  it "prints sequence to set terminal title" do
    expect(`#{binary} test`).to eq("\e]0;test\a")
  end

  it "handles colors by their CSS name" do
    expect(`#{binary} -c pink test`).to eq(
      "\e]6;1;bg;red;brightness;255\a"+
      "\e]6;1;bg;green;brightness;192\a"+
      "\e]6;1;bg;blue;brightness;203\a"+
      "\e]0;test\a"
    )
  end
end
