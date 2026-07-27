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
      expect(output).to eq("")
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
      dedup_files("dir")
      expect(env).to have_content([
        "dir", "dir/data.txt", "dir/link", "outside", "outside/data.txt",
      ])
    end
  end
end
