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

  def flickr_get(*args)
    IO.popen(["ruby", "-r#{__dir__}/mock_network", binary.to_s, *args], &:read)
  end

  it "downloads photo with license in filename" do
    MockUnix.new do |env|
      env.mock_command "wget"
      output = flickr_get("--out", "out", "https://www.flickr.com/photos/naikaklutz/6752498919/")
      url = "https://live.staticflickr.com/7020/6752498919_066c81308f_o.jpg"
      expect(output).to eq([
        url,
        "Cat by naikaklutz from flickr (CC-NC-SA)",
        "out/cat_by_naikaklutz_from_flickr_cc-nc-sa.jpg",
      ].join("\n") + "\n")
      expect(env.command_trace("wget")).to eq([
        ["-nv", url, "-O", "out/cat_by_naikaklutz_from_flickr_cc-nc-sa.jpg"],
      ])
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
