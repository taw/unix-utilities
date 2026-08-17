# bin/media_size only reports anything when executed directly, so loading it
# here just defines the classes. Its cache constant is built at load time out of
# $HOME, so point that somewhere harmless first.
saved_home = ENV["HOME"]
ENV["HOME"] = Dir.mktmpdir
load Pathname(__dir__)+"../bin/media_size"
ENV["HOME"] = saved_home

describe "media_size" do
  describe MediaDirectory do
    let(:dir) { MediaDirectory.new("media") }

    def make_media_dir
      FileUtils.mkdir_p "media"
      %w[a.mp3 b.mp3 c.mp3].each{|f| Pathname("media/#{f}").write("") }
    end

    # sshfs hands out EINTR, and find starts over from the beginning when it
    # does, so an interrupted pass used to leave its files in the list and get
    # counted all over again
    def interrupt_find_once!
      attempt = 0
      allow(dir).to receive(:find) do |&block|
        attempt += 1
        block.call(Pathname("media"))
        block.call(Pathname("media/a.mp3"))
        raise Errno::EINTR if attempt == 1
        block.call(Pathname("media/b.mp3"))
        block.call(Pathname("media/c.mp3"))
      end
    end

    it "lists media files" do
      MockUnix.new do
        make_media_dir
        expect(dir.media_files.map(&:to_s)).to eq(["media/a.mp3", "media/b.mp3", "media/c.mp3"])
      end
    end

    it "doesn't list a file twice when find gets interrupted" do
      MockUnix.new do
        make_media_dir
        interrupt_find_once!
        files = nil
        expect{ files = dir.media_files }.to output("EINTR, retrying\n").to_stderr
        expect(files.map(&:to_s)).to eq(["media/a.mp3", "media/b.mp3", "media/c.mp3"])
      end
    end

    it "doesn't count a file twice when find gets interrupted" do
      MockUnix.new do
        make_media_dir
        interrupt_find_once!
        allow_any_instance_of(MediaFile).to receive(:duration).and_return(10)
        duration = nil
        expect{ duration = dir.duration }.to output("EINTR, retrying\n").to_stderr
        expect(duration).to eq(30)
      end
    end

    it "gives up instead of returning a partial listing" do
      MockUnix.new do
        make_media_dir
        allow(dir).to receive(:find).and_raise(Errno::EINTR)
        expect{
          expect{ dir.media_files }.to raise_error(Errno::EINTR, /gave up on media after 5 attempts/)
        }.to output("EINTR, retrying\n" * 5).to_stderr
      end
    end

    it "reports a directory it gave up on as zero, without dying" do
      MockUnix.new do
        make_media_dir
        allow(dir).to receive(:find).and_raise(Errno::EINTR)
        expect{ expect(dir.duration).to eq(0) }.to output(/FAIL: .*gave up on media/).to_stderr
      end
    end
  end
end
