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
end
