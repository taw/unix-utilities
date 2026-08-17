require "io/console"
require "pty"

describe "xmlview" do
  let(:binary) { Pathname(__dir__)+"../bin/xmlview" }

  # $COLUMNS and $PAGER both change the output, so never inherit them
  def xmlview(*args, env: {}, **kwargs)
    Open3.capture3({"COLUMNS" => nil, "PAGER" => nil}.merge(env), binary.to_s, *args, **kwargs)
  end

  # Only way to get the script to believe it's talking to a terminal, and the
  # only way to give that terminal a specific width
  def xmlview_on_terminal(*args, columns:, env: {})
    master, slave = PTY.open
    master.winsize = [24, columns]
    pid = spawn({"COLUMNS" => nil, "PAGER" => ""}.merge(env), binary.to_s, *args, out: slave, err: slave)
    slave.close
    output = +""
    Timeout.timeout(30) do
      begin
        loop{ output << master.readpartial(4096) }
      rescue EOFError, Errno::EIO
        # Child is done with the pty
      end
      Process.wait(pid)
    end
    master.close
    output
  end

  it "indents xml one space per level" do
    out, err, status = xmlview(stdin_data: '<?xml version="1.0"?><root><a x="1"><b>text</b><c/></a><empty></empty></root>')
    expect(err).to eq("")
    expect(status).to be_success
    expect(out).to eq(
'<?xml version="1.0"?>
<root>
 <a x="1">
  <b>text</b>
  <c/>
 </a>
 <empty/>
</root>
')
  end

  it "reindents xml which was indented some other way" do
    out, _, _ = xmlview(stdin_data: "<root>\n    <a>\n        <b>t</b>\n    </a>\n</root>\n")
    expect(out).to eq(
'<?xml version="1.0"?>
<root>
 <a>
  <b>t</b>
 </a>
</root>
')
  end

  it "leaves mixed content alone" do
    out, _, _ = xmlview(stdin_data: "<p>hello <b>world</b> bye</p>")
    expect(out).to eq(
'<?xml version="1.0"?>
<p>hello <b>world</b> bye</p>
')
  end

  it "reads a file passed as an argument" do
    MockUnix.new do |env|
      Pathname("in.xml").write("<root><a>x</a></root>")
      out, err, status = xmlview("in.xml")
      expect(err).to eq("")
      expect(status).to be_success
      expect(out).to eq("<?xml version=\"1.0\"?>\n<root>\n <a>x</a>\n</root>\n")
    end
  end

  it "cuts long lines to the terminal width" do
    MockUnix.new do |env|
      Pathname("in.xml").write(%Q[<r><a t="#{"x" * 400}"/></r>])
      out = xmlview_on_terminal("in.xml", columns: 60)
      expect(out.lines.map(&:chomp).map(&:size).max).to eq(60)
      out = xmlview_on_terminal("in.xml", columns: 200)
      expect(out.lines.map(&:chomp).map(&:size).max).to eq(200)
    end
  end

  it "cuts long lines to $COLUMNS when it's set" do
    out, _, _ = xmlview(stdin_data: %Q[<r><a t="#{"x" * 400}"/></r>], env: {"COLUMNS" => "40"})
    expect(out.lines.map(&:chomp).map(&:size).max).to eq(40)
  end

  it "prefers $COLUMNS over the terminal width" do
    MockUnix.new do |env|
      Pathname("in.xml").write(%Q[<r><a t="#{"x" * 400}"/></r>])
      out = xmlview_on_terminal("in.xml", columns: 60, env: {"COLUMNS" => "40"})
      expect(out.lines.map(&:chomp).map(&:size).max).to eq(40)
    end
  end

  it "cuts long lines to 150 columns when there's no terminal to measure" do
    out, _, _ = xmlview(stdin_data: %Q[<r><a t="#{"x" * 400}"/></r>])
    expect(out.lines.map(&:chomp).map(&:size).max).to eq(150)
  end

  it "ignores a junk $COLUMNS" do
    out, _, _ = xmlview(stdin_data: %Q[<r><a t="#{"x" * 400}"/></r>], env: {"COLUMNS" => "wide please"})
    expect(out.lines.map(&:chomp).map(&:size).max).to eq(150)
  end

  it "reports parse errors, but still shows whatever parsed" do
    out, err, status = xmlview(stdin_data: "<root><a></b></root>")
    expect(err).to include("Opening and ending tag mismatch")
    expect(out).to eq("<?xml version=\"1.0\"?>\n<root>\n <a/>\n</root>\n")
    expect(status).to be_success
  end

  it "fails when the input isn't xml at all" do
    out, err, status = xmlview(stdin_data: "hello world")
    expect(err).to include("No XML found")
    expect(out).to eq("")
    expect(status).to_not be_success
  end

  it "fails when the file can't be read" do
    MockUnix.new do |env|
      out, err, status = xmlview("no_such_file.xml")
      expect(err).to include("Can't read no_such_file.xml")
      expect(out).to eq("")
      expect(status).to_not be_success
    end
  end

  it "pipes through $PAGER when output is a terminal" do
    MockUnix.new do |env|
      env.mock_command("mock_pager")
      Pathname("in.xml").write("<root><a>x</a></root>")
      Timeout.timeout(30) do
        PTY.spawn({"PAGER" => "mock_pager"}, binary.to_s, "in.xml") do |_r, _w, pid|
          Process.wait(pid) rescue nil
        end
      end
      expect(env.command_trace("mock_pager")).to eq([[]])
    end
  end

  it "doesn't page when output isn't a terminal" do
    MockUnix.new do |env|
      env.mock_command("mock_pager")
      Pathname("in.xml").write("<root><a>x</a></root>")
      out, _, _ = xmlview("in.xml", env: {"PAGER" => "mock_pager"})
      expect(env.command_trace("mock_pager")).to eq([])
      expect(out).to eq("<?xml version=\"1.0\"?>\n<root>\n <a>x</a>\n</root>\n")
    end
  end
end
