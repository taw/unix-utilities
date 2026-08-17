# bin/flickr_get only downloads anything when executed directly, so loading it
# here just defines FlickrGetter
load Pathname(__dir__)+"../bin/flickr_get"

describe "flickr_get" do
  let(:binary) { Pathname(__dir__)+"../bin/flickr_get" }

  describe "extract_photo_id" do
    let(:getter) { FlickrGetter.new("out") }

    # The id is never simply the last number in the URL
    {
      "https://www.flickr.com/photos/naikaklutz/6752498919/" => "6752498919",
      "https://www.flickr.com/photos/naikaklutz/6752498919/in/album-72157629178690711/" => "6752498919",
      "https://flickr.com/photos/12345678@N00/6752498919/sizes/l/" => "6752498919",
      "https://live.staticflickr.com/7020/6752498919_066c81308f_o.jpg" => "6752498919",
      "https://farm8.staticflickr.com/7020/6752498919_066c81308f_b.jpg" => "6752498919",
      "http://farm8.static.flickr.com/7020/6752498919_066c81308f.jpg" => "6752498919",
      "6752498919" => "6752498919",
    }.each do |arg, photo_id|
      it "extracts #{photo_id} from #{arg}" do
        expect(getter.extract_photo_id(arg)).to eq(photo_id)
      end
    end

    ["https://www.flickr.com/photos/naikaklutz/albums/72157629178690711",
     "not a flickr url at all",
     ""].each do |arg|
      it "refuses to guess an id from #{arg.inspect}" do
        expect{ getter.extract_photo_id(arg) }.to raise_error(/Parse error/)
      end
    end
  end

  describe "url_from_getsizes" do
    let(:getter) { FlickrGetter.new("out") }

    it "picks the widest size" do
      sizes = {"sizes" => {"size" => [
        {"width" => "500",  "source" => "small.jpg"},
        {"width" => "2048", "source" => "big.jpg"},
        {"width" => "1024", "source" => "medium.jpg"},
      ]}}
      expect(getter.url_from_getsizes(sizes)).to eq("big.jpg")
    end

    # These used to raise NoMethodError on nil, so the caller's "no sizes"
    # branch could never run
    it "returns nil when the photo has no sizes" do
      expect(getter.url_from_getsizes({"sizes" => {"size" => []}})).to eq(nil)
    end

    it "returns nil when the response has no sizes at all" do
      expect(getter.url_from_getsizes({})).to eq(nil)
    end
  end

  def flickr_get(*args)
    IO.popen(["ruby", "-r#{__dir__}/mock_network", binary.to_s, *args], &:read)
  end

  def flickr_get3(*args, **kwargs)
    Open3.capture3("ruby", "-r#{__dir__}/mock_network", binary.to_s, *args, **kwargs)
  end

  # The photo response in the cassette has a placeholder body - the real one is
  # a 4MB jpeg, and none of this cares what the bytes actually are
  it "downloads photo with license in filename" do
    MockUnix.new do |env|
      output = flickr_get("--out", "out", "https://www.flickr.com/photos/naikaklutz/6752498919/")
      url = "https://live.staticflickr.com/7020/6752498919_066c81308f_o.jpg"
      expect(output).to eq([
        url,
        "Cat by naikaklutz from flickr (CC-NC-SA)",
        "out/cat_by_naikaklutz_from_flickr_cc-nc-sa.jpg",
      ].join("\n") + "\n")
      expect(File.binread("out/cat_by_naikaklutz_from_flickr_cc-nc-sa.jpg")).to eq("fake jpeg data for tests")
    end
  end

  describe "download!" do
    let(:getter) { FlickrGetter.new("out") }
    let(:url) { "https://live.staticflickr.com/7020/6752498919_066c81308f_o.jpg" }

    def response(klass, code)
      klass.new("1.1", code, "").tap{|r| allow(r).to receive(:body).and_return("") }
    end

    it "leaves no file behind when the download fails" do
      MockUnix.new do
        allow(Net::HTTP).to receive(:get_response).and_return(response(Net::HTTPNotFound, "404"))
        expect{ getter.download!(url, "out/cat.jpg") }.to raise_error(/HTTP 404/)
        expect(File.exist?("out/cat.jpg")).to eq(false)
      end
    end

    it "leaves no file behind when the connection fails" do
      MockUnix.new do
        allow(Net::HTTP).to receive(:get_response).and_raise(SocketError, "no route to host")
        expect{ getter.download!(url, "out/cat.jpg") }.to raise_error(SocketError)
        expect(File.exist?("out/cat.jpg")).to eq(false)
      end
    end

    it "follows redirects" do
      MockUnix.new do
        redirect = response(Net::HTTPMovedPermanently, "301")
        redirect["location"] = url
        ok = Net::HTTPOK.new("1.1", "200", "OK")
        allow(ok).to receive(:body).and_return("photo bytes")
        allow(Net::HTTP).to receive(:get_response).and_return(redirect, ok)
        getter.download!("http://farm8.static.flickr.com/7020/6752498919_066c81308f.jpg", "out/cat.jpg")
        expect(File.binread("out/cat.jpg")).to eq("photo bytes")
      end
    end

    it "gives up on a redirect loop" do
      MockUnix.new do
        redirect = response(Net::HTTPMovedPermanently, "301")
        redirect["location"] = url
        allow(Net::HTTP).to receive(:get_response).and_return(redirect)
        expect{ getter.download!(url, "out/cat.jpg") }.to raise_error(/Too many redirects/)
        expect(File.exist?("out/cat.jpg")).to eq(false)
      end
    end
  end

  # Every one of these used to abort the whole run, so a typo in the middle of a
  # long list meant everything after it was silently never downloaded
  describe "batches" do
    let(:good_url) { "https://www.flickr.com/photos/naikaklutz/6752498919/" }
    let(:downloaded) { "out/cat_by_naikaklutz_from_flickr_cc-nc-sa.jpg" }

    it "carries on after an unparseable argument" do
      MockUnix.new do
        out, err, status = flickr_get3("--out", "out", "not a flickr url", good_url)
        expect(err).to match(/Failed to get not a flickr url: Parse error/)
        expect(out).to include(downloaded)
        expect(File.binread(downloaded)).to eq("fake jpeg data for tests")
        expect(status).to_not be_success
      end
    end

    it "carries on after an API error" do
      MockUnix.new do
        out, err, status = flickr_get3("--out", "out", "1", good_url)
        expect(err).to match(/Failed to get 1: Flickr API error in flickr\.photos\.getInfo/)
        expect(out).to include(downloaded)
        expect(File.exist?(downloaded)).to eq(true)
        expect(status).to_not be_success
      end
    end

    it "succeeds when every photo in the batch works" do
      MockUnix.new do
        out, err, status = flickr_get3("--out", "out", good_url)
        expect(err).to eq("")
        expect(out).to include(downloaded)
        expect(status).to be_success
      end
    end

    it "skips blank lines on stdin" do
      MockUnix.new do
        out, err, status = flickr_get3("--out", "out", stdin_data: "\n#{good_url}\n\n")
        expect(err).to eq("")
        expect(out).to include(downloaded)
        expect(status).to be_success
      end
    end
  end

  it "reports error for nonexistent photo" do
    MockUnix.new do |env|
      env.mock_command "wget"
      output = IO.popen(
        ["ruby", "-r#{__dir__}/mock_network", binary.to_s, "--out", "out", "1"],
        err: [:child, :out],
        &:read
      )
      expect(output).to match(/Flickr API error in flickr\.photos\.getInfo: Photo "1" not found/)
      expect(env.command_trace("wget")).to eq([])
    end
  end
end
