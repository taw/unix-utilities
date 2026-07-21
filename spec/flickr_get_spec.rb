describe "flickr_get" do
  let(:binary) { Pathname(__dir__)+"../bin/flickr_get" }

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
