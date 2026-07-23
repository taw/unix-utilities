describe "trash_size" do
  let(:binary) { Pathname(__dir__)+"../bin/trash_size" }

  it "measures how much is in the trash" do
    MockUnix.new do |env|
      env.mock_command "du"
      system({"HOME" => env.path.to_s}, binary.to_s)
      expect(env.command_trace("du")).to eq([
        ["-hs", "#{env.path}/.Trash/"],
      ])
    end
  end
end
