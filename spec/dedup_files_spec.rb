describe "dedup_files" do
  let(:binary) { Pathname(__dir__)+"../bin/dedup_files" }

  def dedup_files(*args)
    IO.popen([binary.to_s, *args], err: [:child, :out], &:read)
  end

  it "deletes duplicates, keeping the file from the earlier directory" do
    MockUnix.new do |env|
      (env.path+"a").mkpath
      (env.path+"b").mkpath
      (env.path+"a/photo.jpg").write("same content")
      (env.path+"b/photo.jpg").write("same content")
      output = dedup_files("a", "b")
      expect(output).to eq("`b/photo.jpg' is a duplicate of `a/photo.jpg'\n12 bytes in duplicated files\n")
      expect(env).to have_content(["a", "a/photo.jpg", "b"])
    end
  end

  it "keeps files which only have the same size" do
    MockUnix.new do |env|
      (env.path+"one.txt").write("aaaa")
      (env.path+"two.txt").write("bbbb")
      dedup_files(".")
      expect(env).to have_content(["one.txt", "two.txt"])
    end
  end

  it "skips symlinks instead of deduplicating them against their target" do
    MockUnix.new do |env|
      (env.path+"data.txt").write("same content")
      (env.path+"link.txt").make_symlink("data.txt")
      output = dedup_files(".")
      expect(output).to eq("Ignoring symlink `link.txt'\n")
      expect(env).to have_content(["data.txt", "link.txt"])
    end
  end

  it "doesn't follow symlinked directories out of the tree" do
    MockUnix.new do |env|
      (env.path+"outside").mkpath
      (env.path+"outside/data.txt").write("same content")
      (env.path+"dir").mkpath
      (env.path+"dir/data.txt").write("same content")
      (env.path+"dir/link").make_symlink("../outside")
      output = dedup_files("dir")
      expect(output).to eq("Ignoring symlink `dir/link'\n")
      expect(env).to have_content([
        "dir", "dir/data.txt", "dir/link", "outside", "outside/data.txt",
      ])
    end
  end

  it "warns about a symlink passed as an argument" do
    MockUnix.new do |env|
      (env.path+"dir").mkpath
      (env.path+"dir/data.txt").write("same content")
      (env.path+"link").make_symlink("dir")
      output = dedup_files("link")
      expect(output).to eq("Ignoring symlink `link'\n")
      expect(env).to have_content(["dir", "dir/data.txt", "link"])
    end
  end

  # Every one of these used to delete the only copy of every file it saw,
  # reporting each as a duplicate of itself
  describe "overlapping arguments" do
    def two_files!(env)
      (env.path+"dir/sub").mkpath
      (env.path+"dir/one.txt").write("content")
      (env.path+"dir/sub/two.txt").write("other content")
    end

    def expect_refused(env, output, message)
      expect(output).to eq("#{message}\nFiles would be deleted as duplicates of themselves, aborting\n")
      expect(env).to have_content(["dir", "dir/one.txt", "dir/sub", "dir/sub/two.txt"])
    end

    it "refuses the same directory twice" do
      MockUnix.new do |env|
        two_files!(env)
        expect_refused env, dedup_files("dir", "dir"), "`dir' and `dir' are the same place"
      end
    end

    it "refuses the same directory spelled two ways" do
      MockUnix.new do |env|
        two_files!(env)
        expect_refused env, dedup_files("./dir", "dir"), "`./dir' and `dir' are the same place"
      end
    end

    it "refuses a directory inside another" do
      MockUnix.new do |env|
        two_files!(env)
        expect_refused env, dedup_files("dir", "dir/sub"), "`dir' and `dir/sub' overlap"
      end
    end

    it "refuses a file inside a directory it was also given" do
      MockUnix.new do |env|
        two_files!(env)
        expect_refused env, dedup_files("dir/one.txt", "dir"), "`dir/one.txt' and `dir' overlap"
      end
    end

    it "exits with an error" do
      MockUnix.new do |env|
        two_files!(env)
        system binary.to_s, "dir", "dir", out: File::NULL, err: File::NULL
        expect($?).to_not be_success
      end
    end

    it "allows sibling directories which only share a name prefix" do
      MockUnix.new do |env|
        (env.path+"foo").mkpath
        (env.path+"foobar").mkpath
        (env.path+"foo/photo.jpg").write("same content")
        (env.path+"foobar/photo.jpg").write("same content")
        output = dedup_files("foo", "foobar")
        expect(output).to eq("`foobar/photo.jpg' is a duplicate of `foo/photo.jpg'\n12 bytes in duplicated files\n")
      end
    end

    it "isn't confused by a symlink pointing at another argument" do
      MockUnix.new do |env|
        two_files!(env)
        (env.path+"link").make_symlink("dir")
        output = dedup_files("dir", "link")
        expect(output).to eq("Ignoring symlink `link'\n")
        expect(env).to have_content(["dir", "dir/one.txt", "dir/sub", "dir/sub/two.txt", "link"])
      end
    end
  end
end
