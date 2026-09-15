require "digest"

describe "webman" do
  let(:binary) { Pathname(__dir__)+"../bin/webman" }

  # webman caches under $HOME/.man_cache, so every test gets its own HOME to
  # avoid touching (or depending on) the real one.
  def webman(*args, home:)
    Open3.capture3({"HOME" => home.to_s}, binary.to_s, *args)
  end

  def cache_key(cmd)
    Digest::MD5.hexdigest(cmd.inspect)
  end

  it "renders the man page to html and opens it in the browser" do
    MockUnix.new do |env|
      Pathname("fakepage.1").write("fake man page content")
      env.mock_command "man", stdout: (env.path+"fakepage.1").to_s
      env.mock_command "groff", stdout: "<html>fake man html</html>"
      env.mock_command "open"

      _, err, status = webman("ls", home: env.path+"home")
      expect(err).to eq("")
      expect(status).to be_success

      html_path = env.path+"home/.man_cache/#{cache_key(["ls"])}.html"
      expect(env.command_trace("man")).to eq([["-w", "ls"]])
      expect(env.command_trace("open")).to eq([[html_path.to_s]])
    end
  end

  it "falls back to a Google search when rendering the man page fails" do
    MockUnix.new do |env|
      Pathname("fakepage.1").write("fake man page content")
      env.mock_command "man", stdout: (env.path+"fakepage.1").to_s
      env.mock_command "groff", exit_status: 1
      env.mock_command "open"

      _, _, status = webman("ls", "foo", home: env.path+"home")
      expect(status).to be_success
      expect(env.command_trace("open")).to eq([
        ["http://www.google.com/search?q=man+ls+foo"],
      ])
    end
  end

  it "falls back to a Google search when the command has no man page" do
    MockUnix.new do |env|
      env.mock_command "man"
      env.mock_command "open"

      _, _, status = webman("nosuchcommand", home: env.path+"home")
      expect(status).to be_success
      expect(env.command_trace("open")).to eq([
        ["http://www.google.com/search?q=man+nosuchcommand"],
      ])
    end
  end

  it "displays the man page in the terminal with -T" do
    MockUnix.new do |env|
      Pathname("fakepage.1").write("fake man page content")
      env.mock_command "man", stdout: (env.path+"fakepage.1").to_s

      _, err, status = webman("-T", "ls", "foo", home: env.path+"home")
      expect(err).to eq("")
      expect(status).to be_success

      cache_path = env.path+"home/.man_cache/#{cache_key(["ls", "foo"])}"
      expect(env.command_trace("man")).to eq([
        ["-w", "ls", "foo"],
        [cache_path.to_s],
      ])
    end
  end

  it "escapes shell metacharacters in the page name" do
    MockUnix.new do |env|
      Pathname("fakepage.1").write("fake man page content")
      env.mock_command "man", stdout: (env.path+"fakepage.1").to_s
      env.mock_command "groff", stdout: "<html>fake man html</html>"
      env.mock_command "open"

      _, err, status = webman("foo(1)", home: env.path+"home")
      expect(err).to eq("")
      expect(status).to be_success
      expect(env.command_trace("man")).to eq([["-w", "foo(1)"]])
    end
  end

  it "does not let the page name inject shell commands" do
    MockUnix.new do |env|
      env.mock_command "man"
      env.mock_command "open"
      marker = env.path+"injected"

      webman("foo; touch #{marker}", home: env.path+"home")

      expect(marker).to_not exist
    end
  end

  it "fails when asked for the terminal page of a command with no man page" do
    MockUnix.new do |env|
      env.mock_command "man"

      _, err, status = webman("-T", "nosuchcommand", home: env.path+"home")
      expect(err).to include("File doesn't exist")
      expect(status).to_not be_success
    end
  end
end
