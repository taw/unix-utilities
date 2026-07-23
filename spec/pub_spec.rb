describe "pub" do
  let(:binary) { Pathname(__dir__)+"../bin/pub" }

  def mode(path)
    "%o" % (Pathname(path).stat.mode & 0777)
  end

  it "makes files readable by everybody" do
    MockUnix.new do |env|
      (env.path+"data.txt").write("")
      (env.path+"data.txt").chmod(0600)
      system binary.to_s, "data.txt"
      expect(mode("data.txt")).to eq("644")
    end
  end

  it "keeps executable files executable" do
    MockUnix.new do |env|
      (env.path+"script").write("#!/bin/sh\n")
      (env.path+"script").chmod(0700)
      system binary.to_s, "script"
      expect(mode("script")).to eq("755")
    end
  end

  it "descends into directories" do
    MockUnix.new do |env|
      (env.path+"dir/sub").mkpath
      (env.path+"dir/sub/data.txt").write("")
      (env.path+"dir/sub/data.txt").chmod(0600)
      (env.path+"dir/sub").chmod(0700)
      (env.path+"dir").chmod(0700)
      system binary.to_s, "dir"
      expect(mode("dir")).to eq("755")
      expect(mode("dir/sub")).to eq("755")
      expect(mode("dir/sub/data.txt")).to eq("644")
    end
  end

  it "warns about files which don't exist" do
    MockUnix.new do |env|
      output = IO.popen([binary.to_s, "nosuchfile"], err: [:child, :out], &:read)
      expect(output).to eq("File nosuchfile doesn't exist\n")
    end
  end
end
