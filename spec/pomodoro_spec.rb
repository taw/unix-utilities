# bin/pomodoro only runs the pomodoro when executed directly, so loading it here
# just defines the helpers, and the counting can be tested without waiting minutes
load Pathname(__dir__)+"../bin/pomodoro"

describe "pomodoro" do
  let(:binary) { Pathname(__dir__)+"../bin/pomodoro" }

  it "plays the alert at full volume, then puts the volume back" do
    MockUnix.new do |env|
      env.mock_command "osascript", stdout: "42\n"
      env.mock_command "afplay"
      system "#{binary} 0"
      expect(env.command_trace("osascript")).to eq([
        ["-e", "output volume of (get volume settings)"],
        ["-e", "set volume output volume 100"],
        ["-e", "set volume output volume 42"],
      ])
      expect(env.command_trace("afplay")).to eq([
        ["/System/Library/Sounds/Ping.aiff"],
      ])
    end
  end

  it "says so when the sound can't be played, instead of ending in silence" do
    MockUnix.new do |env|
      env.mock_command "osascript", stdout: "42\n"
      env.mock_command "afplay", exit_status: 1
      expect(`#{binary} 0 2>&1`).to eq(
        "Couldn't play `/System/Library/Sounds/Ping.aiff'\n"
      )
      expect(env.command_trace("osascript").last).to eq(
        ["-e", "set volume output volume 42"]
      )
    end
  end

  describe "pomodoro!" do
    before { allow(self).to receive(:with_volume) }

    # pomodoro! calls check_commands! in this very process, so without the mocks
    # on PATH it would exit rspec itself on any system without osascript/afplay
    around do |example|
      MockUnix.new do |env|
        env.mock_command "osascript"
        env.mock_command "afplay"
        example.run
      end
    end

    it "counts the minutes given as the first argument" do
      expect(self).to receive(:count_minutes!).with(5)
      pomodoro! ["5"]
    end

    it "counts 25 minutes when given no argument" do
      expect(self).to receive(:count_minutes!).with(25)
      pomodoro! []
    end
  end

  describe "count_minutes!" do
    # Only sleep_until is stubbed below, so a change which goes back to sleeping
    # directly would wait out the real minutes rather than failing
    before { allow(self).to receive(:sleep) }

    it "counts down every minute it was asked for" do
      allow(self).to receive(:sleep_until)
      expect{ count_minutes!(3, Time.at(0)) }.to output(
        "Minutes to go: 3\nMinutes to go: 2\nMinutes to go: 1\n"
      ).to_stdout
    end

    it "waits until whole minutes from the start, so slow iterations don't add up" do
      deadlines = []
      allow(self).to receive(:sleep_until){|time| deadlines << time}
      expect{ count_minutes!(3, Time.at(0)) }.to output.to_stdout
      expect(deadlines).to eq([Time.at(60), Time.at(120), Time.at(180)])
    end

    it "waits for nothing when asked for zero minutes" do
      expect(self).not_to receive(:sleep_until)
      expect{ count_minutes!(0, Time.at(0)) }.to output("").to_stdout
    end
  end

  describe "sleep_until" do
    it "sleeps the time still remaining" do
      slept = nil
      allow(self).to receive(:sleep){|seconds| slept = seconds}
      sleep_until Time.now + 5
      expect(slept).to be_within(0.1).of(5)
    end

    # This is what keeps an iteration that overran from pushing out the next one
    it "doesn't sleep when the deadline has already passed" do
      expect(self).not_to receive(:sleep)
      sleep_until Time.now - 5
    end
  end
end
