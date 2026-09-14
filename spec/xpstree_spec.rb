describe "xpstree" do
  let(:binary) { Pathname(__dir__)+"../bin/xpstree" }

  # A small fixed process table, standing in for real `ps` output. UID matches
  # the current user so -u/-f/-F filters that key off Process.uid are testable.
  def fake_ps(env)
    env.mock_command "ps", stdout: <<~PS
        PID  PPID   UID USER            COMMAND
          1     0     0 root            /sbin/launchd
        200     1   #{Process.uid} tester          -zsh
        201   200   #{Process.uid} tester          ruby script.rb
        202     1     0 root            kernel_task
    PS
  end

  def xpstree(*args)
    Open3.capture3(binary.to_s, *args)
  end

  it "renders the process tree" do
    MockUnix.new do |env|
      fake_ps(env)
      out, err, status = xpstree
      expect(err).to eq("")
      expect(status).to be_success
      expect(out).to eq(<<~OUT)
        launchd-+-zsh(tester)---script.rb
                `-kernel_task
      OUT
    end
  end

  it "prints PIDs with -p" do
    MockUnix.new do |env|
      fake_ps(env)
      out, _, status = xpstree("-p")
      expect(status).to be_success
      expect(out).to eq(<<~OUT)
        launchd(1)-+-zsh(200,tester)---script.rb(201)
                   `-kernel_task(202)
      OUT
    end
  end

  it "focuses on the current user's processes with -u" do
    MockUnix.new do |env|
      fake_ps(env)
      out, _, status = xpstree("-u")
      expect(status).to be_success
      expect(out).to eq("zsh---script.rb\n")
    end
  end

  it "prunes processes matching -x" do
    MockUnix.new do |env|
      fake_ps(env)
      out, _, status = xpstree("-x", "zsh")
      expect(status).to be_success
      expect(out).to eq("launchd---kernel_task\n")
    end
  end

  it "prunes processes matching a regexp with -X" do
    MockUnix.new do |env|
      fake_ps(env)
      out, _, status = xpstree("-X", "z.h")
      expect(status).to be_success
      expect(out).to eq("launchd---kernel_task\n")
    end
  end

  it "prints full command lines with --raw" do
    MockUnix.new do |env|
      fake_ps(env)
      out, _, status = xpstree("--raw")
      expect(status).to be_success
      expect(out).to eq(<<~OUT)
        /sbin/launchd
          |--zsh(tester)
          |   `-ruby script.rb
          `-kernel_task
      OUT
    end
  end

  it "highlights matching processes and their ancestors with -h" do
    MockUnix.new do |env|
      fake_ps(env)
      out, _, status = xpstree("-h", "zsh")
      expect(status).to be_success
      expect(out).to eq(
        "\e[1;37m\e[44mlaunchd\e[0m-+-\e[1;37m\e[44mzsh(tester)\e[0m---script.rb\n" \
        "        `-kernel_task\n"
      )
    end
  end
end
