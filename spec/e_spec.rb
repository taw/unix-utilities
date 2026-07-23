describe "e" do
  let(:binary) { Pathname(__dir__)+"../bin/e" }

  # Runs `e` with a mocked editor, and returns the arguments it got
  def run_e(env, *args)
    system({"E_EDITOR" => "myeditor"}, binary.to_s, *args)
    env.command_trace("myeditor").first
  end

  # An executable script somewhere in PATH, reached through a symlink
  # relative to the symlink's directory, like homebrew's bin/foo -> ../Cellar/foo
  def mock_script_in_path(env, name, content="#!/usr/bin/env ruby\n")
    (env.path+"real").mkpath
    (env.path+"pathdir").mkpath
    script = env.path+"real"+name
    script.write(content)
    script.chmod(0755)
    (env.path+"pathdir"+name).make_symlink("../real/#{name}")
    ENV["PATH"] = "#{env.path+"pathdir"}:#{ENV["PATH"]}"
    script.realpath
  end

  it "opens scripts found in PATH, resolving symlinks relative to the symlink" do
    MockUnix.new do |env|
      env.mock_command "myeditor"
      script = mock_script_in_path(env, "mytool")
      expect(run_e(env, "mytool")).to eq([script.to_s])
    end
  end

  it "leaves alone commands in PATH which aren't scripts" do
    MockUnix.new do |env|
      env.mock_command "myeditor"
      mock_script_in_path(env, "mybinary", "\x7FELF not a script at all")
      expect(run_e(env, "mybinary")).to eq(["mybinary"])
    end
  end

  it "leaves alone existing files, paths, and options" do
    MockUnix.new do |env|
      env.mock_command "myeditor"
      (env.path+"existing.txt").write("")
      expect(run_e(env, "existing.txt", "sub/dir/file.txt", "-w")).to eq(
        ["existing.txt", "sub/dir/file.txt", "-w"]
      )
    end
  end

  it "leaves alone names which are neither files nor commands" do
    MockUnix.new do |env|
      env.mock_command "myeditor"
      expect(run_e(env, "brand_new_file")).to eq(["brand_new_file"])
    end
  end

  it "prefers E_EDITOR over EDITOR, and splits it into words" do
    MockUnix.new do |env|
      env.mock_command "myeditor"
      env.mock_command "othereditor"
      system({"E_EDITOR" => "myeditor --flag", "EDITOR" => "othereditor"},
             binary.to_s, "brand_new_file")
      expect(env.command_trace("myeditor")).to eq([["--flag", "brand_new_file"]])
      expect(env.command_trace("othereditor")).to eq([])
    end
  end
end
