describe "toutf8" do
  let(:binary) { Pathname(__dir__)+"../bin/toutf8" }
  let(:path) { Pathname(__dir__) + "toutf8/#{file}.txt" }
  let(:output) { `#{binary} <#{path.to_s.shellescape}` }

  context "empty" do
    let(:file) { "empty" }
    it "leave is as is" do
      expect(output).to eq("")
    end
  end

  context "ascii" do
    let(:file) { "ascii" }
    it "" do
      expect(output).to eq("All your base are belong to us.\n")
    end
  end

  context "UTF-8" do
    let(:file) { "utf8" }
    it "" do
      expect(output).to eq("Żółw błotny.\n")
    end
  end

  context "UTF-8 with BOM" do
    let(:file) { "utf8_bom" }
    it "converts to UTF-8 without BOM" do
      expect(output).to eq("Żółw błotny.\n")
    end
  end

  context "UTF-16-BE" do
    let(:file) { "utf16be" }
    it "converts to UTF-8 without BOM" do
      expect(output).to eq("Żółw błotny.\n")
    end
  end

  context "UTF-16-BE with BOM" do
    let(:file) { "utf16be_bom" }
    it "converts to UTF-8 without BOM" do
      expect(output).to eq("Żółw błotny.\n")
    end
  end

  context "UTF-16-LE" do
    let(:file) { "utf16le" }
    it "converts to UTF-8 without BOM" do
      expect(output).to eq("Żółw błotny.\n")
    end
  end

  context "UTF-16-LE with BOM" do
    let(:file) { "utf16le_bom" }
    it "converts to UTF-8 without BOM" do
      expect(output).to eq("Żółw błotny.\n")
    end
  end

  # NUL bytes are valid US-ASCII, so BOM-less UTF-16 holding only ASCII
  # characters passes the valid_ascii? fast path and is emitted unchanged.
  context "UTF-16-BE without BOM, ASCII-only content" do
    let(:file) { "utf16be_ascii" }
    it "converts to UTF-8 without BOM" do
      expect(output).to eq("All your base are belong to us.\n")
    end
  end

  context "UTF-16-LE without BOM, ASCII-only content" do
    let(:file) { "utf16le_ascii" }
    it "converts to UTF-8 without BOM" do
      expect(output).to eq("All your base are belong to us.\n")
    end
  end

  # 8bit legacy encodings are all guessed as Windows-1252, as there's nothing
  # in the file saying which one it actually is
  context "Latin-1" do
    let(:file) { "latin1" }
    it "converts to UTF-8" do
      expect(output).to eq("Über café naïve.\n")
    end
  end

  context "Windows-1252" do
    let(:file) { "cp1252" }
    it "converts to UTF-8" do
      expect(output).to eq("“Smart quotes” — dash.\n")
    end
  end

  context "bytes no encoding can decode" do
    let(:file) { "cp1252_invalid" }
    it "replaces them instead of crashing" do
      expect(output).to eq("a\u{FFFD}\u{FFFD}\u{FFFD}\u{FFFD}\u{FFFD}b\n")
    end
  end
end
