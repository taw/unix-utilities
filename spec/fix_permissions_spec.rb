describe "fix_permissions" do
  let(:binary) { Pathname(__dir__)+"../bin/fix_permissions" }

  it "normalizes file names" do
    MockUnix.new do |env|
      File.write("foo.sh", "#!/bin/bash\necho 123")
      File.write("foo.rb", "#!/bin/env ruby")
      File.write("hello.txt", "Hello, world!")
      File.write("true", File.read(`which true`.chomp))
      File.write("empty.txt", "")
      system "chmod +x *"
      system "#{binary} *"

      actual = env.path
                  .find
                  .map{|x| [x.relative_path_from(env.path).to_s, x.stat.mode & 0o777] }
                  .select{|x,| x != "."}
                  .sort

      expect(actual).to eq([
        ["empty.txt", 0o666 &~ File.umask],
        ["foo.rb",    0o777 &~ File.umask],
        ["foo.sh",    0o777 &~ File.umask],
        ["hello.txt", 0o666 &~ File.umask],
        ["true",      0o777 &~ File.umask],
      ])
    end
  end
end
