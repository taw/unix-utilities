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

  def unpacks_and_deletes_archive(binary, name, dir="foo")
    system %Q["#{binary}" "#{name}" >/dev/null]
    files = Pathname(".").find.select(&:file?).reject{|n| n.to_s =~ /.DS_Store/}.map{|n| [n.to_s, n.read]}
    expect(files).to eq([["#{dir}/a.txt", "hello"], ["#{dir}/b.txt", "world"]])
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

  # .gem files are uncompressed tars, not gzipped ones. bsdtar ignores the
  # difference, GNU tar does not, so the flags have to be right
  it "unzips archives in gem format" do
    MockUnix.new do |env|
      create_archive do
        system "tar cf foo.gem a.txt b.txt"
      end
      unpacks_and_deletes_archive binary, "foo.gem"
    end
  end

  # These are all zip with a different extension on it. `file` reports most of
  # them as their own mime type, not application/zip, so the fallback for
  # unknown extensions doesn't cover them
  %W[epub docx apk whl cbz].each do |format|
    it "unzips zip archives named .#{format}" do
      MockUnix.new do |env|
        create_archive do
          system "#{SevenZip} a foo.zip a.txt b.txt >/dev/null"
          system "mv foo.zip foo.#{format}"
        end
        unpacks_and_deletes_archive binary, "foo.#{format}"
      end
    end
  end

  it "unzips archives in cpio format" do
    MockUnix.new do |env|
      create_archive do
        system "printf 'a.txt\\nb.txt\\n' | cpio -o >foo.cpio 2>/dev/null"
      end
      unpacks_and_deletes_archive binary, "foo.cpio"
    end
  end

  it "unzips archives in tar.zst format", skip: !have_command?("zstd") do
    MockUnix.new do |env|
      create_archive do
        system "tar c a.txt b.txt | zstd -q >foo.tar.zst"
      end
      unpacks_and_deletes_archive binary, "foo.tar.zst"
    end
  end

  it "unzips archives in tar.Z format", skip: !have_command?("compress") do
    MockUnix.new do |env|
      create_archive do
        system "tar c a.txt b.txt | compress >foo.tar.Z"
      end
      unpacks_and_deletes_archive binary, "foo.tar.Z"
    end
  end

  def reports_empty_archive(binary, name)
    output = `"#{binary}" "#{name}" 2>&1`
    expect($?.success?).to eq(true)
    expect(output).to eq("Empty #{name}\n")
    # Nothing was unpacked, and the archive itself is still there
    files = Pathname(".").find.select(&:file?).reject{|n| n.to_s =~ /.DS_Store/}.map(&:to_s)
    expect(files).to eq([name])
  end

  it "reports empty archives in tar format instead of crashing" do
    MockUnix.new do |env|
      system "tar cf foo.tar -T /dev/null"
      reports_empty_archive binary, "foo.tar"
    end
  end

  it "reports empty archives in 7z format instead of crashing" do
    MockUnix.new do |env|
      system "#{SevenZip} a foo.7z -stl . >/dev/null"
      reports_empty_archive binary, "foo.7z"
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

  # There's no extension to cut off, so the directory is named after the whole
  # archive, and the archive itself is already sitting on that name
  it "unzips archives in .zip format even with no extension at all" do
    MockUnix.new do |env|
      create_archive do
        system "#{SevenZip} a foo.zip a.txt b.txt >/dev/null"
        system "mv foo.zip foo"
      end
      unpacks_and_deletes_archive binary, "foo", "foo-1"
    end
  end

  it "keeps the case of the archive name when naming the directory" do
    MockUnix.new do |env|
      create_archive do
        system "#{SevenZip} a foo.zip a.txt b.txt >/dev/null"
        system "mv foo.zip FOO.ZIP"
      end
      unpacks_and_deletes_archive binary, "FOO.ZIP", "FOO"
    end
  end
end
