describe "unall" do
  let(:binary) { Pathname(__dir__)+"../bin/unall" }

  def self.have_command?(cmd)
    ENV["PATH"].split(File::PATH_SEPARATOR).any?{|dir| File.executable?(File.join(dir, cmd))}
  end

  SevenZip = %w[7zz 7z].find{|cmd| have_command?(cmd)}

  def create_archive
    File.write("a.txt", "hello")
    File.write("b.txt", "world")
    yield
    FileUtils.remove "a.txt"
    FileUtils.remove "b.txt"
  end

  def unpacks_and_deletes_archive(binary, name)
    system %Q["#{binary}" "#{name}" >/dev/null]
    files = Pathname(".").find.select(&:file?).reject{|n| n.to_s =~ /.DS_Store/}.map{|n| [n.to_s, n.read]}
    expect(files).to eq([["foo/a.txt", "hello"], ["foo/b.txt", "world"]])
  end

  %W[7z zip tar].each do |format|
    it "unzips archives in #{format} format" do
      MockUnix.new do |env|
        create_archive do
          system "#{SevenZip} a foo.#{format} a.txt b.txt >/dev/null"
        end
        unpacks_and_deletes_archive binary, "foo.#{format}"
      end
    end
  end

  # Only creating the archive needs `rar`, unpacking goes through 7zip
  it "unzips archives in rar format", skip: !have_command?("rar") do
    MockUnix.new do |env|
      create_archive do
        system "rar a foo.rar a.txt b.txt >/dev/null"
      end
      unpacks_and_deletes_archive binary, "foo.rar"
    end
  end

  it "unzips archives in tar.gz format" do
    MockUnix.new do |env|
      create_archive do
        system "tar c a.txt b.txt | gzip >foo.tar.gz"
      end
      unpacks_and_deletes_archive binary, "foo.tar.gz"
    end
  end

  it "unzips archives in tar.bz2 format" do
    MockUnix.new do |env|
      create_archive do
        system "tar c a.txt b.txt | bzip2 >foo.tar.bz2"
      end
      unpacks_and_deletes_archive binary, "foo.tar.bz2"
    end
  end

  it "unzips archives in .zip format even with nonstandard extension" do
    MockUnix.new do |env|
      create_archive do
        system "#{SevenZip} a foo.zip a.txt b.txt >/dev/null"
        system "mv foo.zip foo.wtf"
      end
      unpacks_and_deletes_archive binary, "foo.wtf"
    end
  end
end
