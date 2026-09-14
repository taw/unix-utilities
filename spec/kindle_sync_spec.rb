describe "kindle_sync" do
  let(:binary) { Pathname(__dir__)+"../bin/kindle_sync" }

  def kindle_sync(*args)
    Open3.capture3(binary.to_s, *args)
  end

  it "lists books grouped by extension, ignoring .sdr sidecars and .DS_Store" do
    MockUnix.new do
      Pathname("repo/authorA").mkpath
      Pathname("repo/authorA/Book One.epub").write("")
      Pathname("repo/authorA/Book One.pdf").write("")
      Pathname("repo/Standalone.pdf").write("")
      Pathname("repo/authorA/Book One.sdr").mkpath
      Pathname("repo/authorA/Book One.sdr/status.json").write("")
      Pathname("repo/.DS_Store").write("")

      out, err, status = kindle_sync("--list", "repo")
      expect(err).to eq("")
      expect(status).to be_success
      expect(out).to eq(<<~OUT)
        Standalone (.pdf)
        authorA/Book One (.epub .pdf)
      OUT
    end
  end

  it "reports books that need syncing and leaves already-synced ones out" do
    MockUnix.new do
      Pathname("repo/authorA").mkpath
      Pathname("repo/authorA/Book One.epub").write("")
      Pathname("repo/authorA/Book One.pdf").write("")
      Pathname("repo/Standalone.pdf").write("")
      Pathname("device").mkpath
      Pathname("device/Standalone.pdf").write("")

      out, _, status = kindle_sync("--report", "repo", "device")
      expect(status).to be_success
      expect(out).to eq("authorA/Book One (.epub .pdf | - | convert_epub)\n")
    end
  end

  it "copies a pdf-only book straight across" do
    MockUnix.new do
      Pathname("repo").mkpath
      Pathname("repo/book.pdf").write("pdf content")
      Pathname("device").mkpath

      _, _, status = kindle_sync("--sync", "repo", "device")
      expect(status).to be_success
      expect(Pathname("device/book.pdf").read).to eq("pdf content")
    end
  end

  it "only copies the .mobi when a repo book has both .epub and .mobi" do
    MockUnix.new do
      Pathname("repo").mkpath
      Pathname("repo/book.epub").write("epub content")
      Pathname("repo/book.mobi").write("mobi content")
      Pathname("device").mkpath

      _, _, status = kindle_sync("--sync", "repo", "device")
      expect(status).to be_success
      expect(Pathname("device/book.mobi").read).to eq("mobi content")
      expect(Pathname("device/book.epub")).to_not exist
    end
  end

  it "leaves a book alone once any .mobi is on the device, regardless of repo state" do
    MockUnix.new do
      Pathname("repo").mkpath
      Pathname("repo/book.epub").write("epub content")
      Pathname("device").mkpath
      Pathname("device/book.mobi").write("device mobi")

      out, _, status = kindle_sync("--report", "repo", "device")
      expect(status).to be_success
      expect(out).to eq("")
    end
  end

  it "requires calibre only when an epub actually needs converting" do
    MockUnix.new do
      Pathname("repo").mkpath
      Pathname("repo/book.epub").write("")
      Pathname("device").mkpath

      out, err, status = kindle_sync("--sync", "repo", "device")
      expect(err).to include("requires /Applications/calibre.app/Contents/MacOS/ebook-convert")
      expect(status.exitstatus).to eq(1)
      expect(out).to eq("")
    end
  end

  it "cleans up device books that no longer exist in the repo" do
    MockUnix.new do |env|
      env.mock_command "trash"
      Pathname("repo").mkpath
      Pathname("device").mkpath
      Pathname("device/gone.pdf").write("stale")

      _, _, status = kindle_sync("--cleanup", "repo", "device")
      expect(status).to be_success
      expect(env.command_trace("trash")).to eq([
        ["device/gone.pdf"],
      ])
    end
  end

  it "prints usage and fails when called without arguments" do
    MockUnix.new do
      _, err, status = kindle_sync
      expect(err).to include("Usage:")
      expect(status.exitstatus).to eq(1)
    end
  end
end
