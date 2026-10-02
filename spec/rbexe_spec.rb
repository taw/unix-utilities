shared_examples "rbexe" do
  it do
    MockUnix.new do |env|
      system "#{binary}", *arguments, "#{file}"
      expect(file).to be_executable
      expect(content).to eq("#!#{interpretter}\n")
    end
  end
end

describe "rbexe" do
  let(:binary) { Pathname(__dir__)+"../bin/rbexe" }
  let(:file) { Pathname("test") }
  let(:content) { file.read }

  context "default" do
    let(:arguments) { %W[] }
    let(:interpretter) { "/usr/bin/env ruby" }
    it_behaves_like "rbexe"
  end

  context "ruby" do
    let(:arguments) { %W[--rb] }
    let(:interpretter) { "/usr/bin/env ruby" }
    it_behaves_like "rbexe"
  end

  context "perl" do
    let(:arguments) { %W[--pl] }
    let(:interpretter) { "/usr/bin/perl" }
    it_behaves_like "rbexe"
  end

  # This means python 2 on pretty much every system out there
  context "python" do
    let(:arguments) { %W[--py] }
    let(:interpretter) { "/usr/bin/env python" }
    it_behaves_like "rbexe"
  end

  context "python 2" do
    let(:arguments) { %W[--py2] }
    let(:interpretter) { "/usr/bin/env python2" }
    it_behaves_like "rbexe"
  end

  context "python 3" do
    let(:arguments) { %W[--py3] }
    let(:interpretter) { "/usr/bin/env python3" }
    it_behaves_like "rbexe"
  end

  it "makes existing files executable, respecting umask" do
    MockUnix.new do |env|
      file.write("hello\n")
      file.chmod(0640)
      system "umask 027 && #{binary} #{file} 2>/dev/null"
      expect(file.stat.mode & 0777).to eq(0750)
      expect(content).to eq("hello\n")
    end
  end

  context "bash" do
    let(:arguments) { %W[--sh] }
    let(:interpretter) { "/bin/bash" }
    it_behaves_like "rbexe"
  end
end
