describe "git_hash" do
  let(:binary) { Pathname(__dir__)+"../bin/git_hash" }

  def git_hash(*args)
    Open3.capture3(binary.to_s, *args)
  end

  # No commits needed anywhere here - ls-files reads the index, so `git add' is
  # enough, and that keeps the specs independent of any git identity config
  def git_repo!(name)
    Pathname(name).mkpath
    Dir.chdir(name) do
      system *%w[git init -q .]
      yield if block_given?
      system *%w[git add -A]
    end
  end

  it "hashes the contents of a repository" do
    MockUnix.new do
      git_repo!("repo") do
        Pathname("one.txt").write("content")
      end
      out, err, status = git_hash("repo")
      expect(err).to eq("")
      expect(status).to be_success
      expect(out).to match(/\A[0-9a-f]{40}\n\z/)
    end
  end

  it "hashes the same contents to the same hash, and different contents differently" do
    MockUnix.new do
      git_repo!("a"){ Pathname("one.txt").write("content") }
      git_repo!("b"){ Pathname("one.txt").write("content") }
      git_repo!("c"){ Pathname("one.txt").write("other content") }
      git_repo!("d"){ Pathname("different_name.txt").write("content") }
      a, b, c, d = %w[a b c d].map{|repo| git_hash(repo).first }
      expect(a).to eq(b)
      expect(a).to_not eq(c)
      expect(a).to_not eq(d)
    end
  end

  it "ignores untracked files" do
    MockUnix.new do
      git_repo!("repo"){ Pathname("one.txt").write("content") }
      before = git_hash("repo").first
      Pathname("repo/untracked.txt").write("whatever")
      expect(git_hash("repo").first).to eq(before)
    end
  end

  # git quotes these in its default output, and the quoted name doesn't exist,
  # so this used to fail with ENOENT for the whole repository
  it "hashes files with non-ASCII names" do
    MockUnix.new do
      git_repo!("repo"){ Pathname("café.txt").write("content") }
      out, err, status = git_hash("repo")
      expect(err).to eq("")
      expect(status).to be_success
      expect(out).to match(/\A[0-9a-f]{40}\n\z/)
    end
  end

  # Used to raise Errno::ENOENT
  it "warns about tracked files which aren't in the working tree" do
    MockUnix.new do
      git_repo!("repo") do
        Pathname("one.txt").write("content")
        Pathname("deleted.txt").write("content")
      end
      Pathname("repo/deleted.txt").unlink
      out, err, status = git_hash("repo")
      expect(err).to eq("Skipping missing file `deleted.txt'\n")
      expect(status).to be_success
      expect(out).to match(/\A[0-9a-f]{40}\n\z/)
    end
  end

  describe "symlinks" do
    it "hashes a symlink as the path it points at" do
      MockUnix.new do
        git_repo!("a"){ Pathname("link").make_symlink("target.txt") }
        git_repo!("b"){ Pathname("link").make_symlink("target.txt") }
        git_repo!("c"){ Pathname("link").make_symlink("elsewhere.txt") }
        a, b, c = %w[a b c].map{|repo| git_hash(repo).first }
        expect(a).to eq(b)
        expect(a).to_not eq(c)
      end
    end

    it "doesn't follow a symlink out of the repository" do
      MockUnix.new do
        Pathname("outside.txt").write("before")
        git_repo!("repo"){ Pathname("link").make_symlink("../outside.txt") }
        before = git_hash("repo")
        Pathname("outside.txt").write("after")
        expect(git_hash("repo")).to eq(before)
      end
    end

    # Following it would be Errno::ENOENT
    it "hashes a symlink pointing nowhere" do
      MockUnix.new do
        git_repo!("repo"){ Pathname("link").make_symlink("no_such_file.txt") }
        out, err, status = git_hash("repo")
        expect(err).to eq("")
        expect(status).to be_success
        expect(out).to match(/\A[0-9a-f]{40}\n\z/)
      end
    end
  end

  it "hashes the current directory when given no arguments" do
    MockUnix.new do
      git_repo!("repo"){ Pathname("one.txt").write("content") }
      expected = git_hash("repo").first
      Dir.chdir("repo") do
        expect(git_hash.first).to eq(expected)
      end
    end
  end

  # Used to print a hash of an empty file list, the same one for any directory
  it "fails outside a git repository" do
    MockUnix.new do
      Pathname("not_a_repo").mkpath
      out, _, status = git_hash("not_a_repo")
      expect(out).to eq("")
      expect(status).to_not be_success
    end
  end
end
