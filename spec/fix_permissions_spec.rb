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
                  .map{|x| [x.relative_path_from(env.path).to_s, ("%o" % x.stat.mode)[-3..-1]] }
                  .select{|x,| x != "."}
                  .sort

      expect(actual).to eq([
        ["empty.txt", "644"],
        ["foo.rb", "755"],
        ["foo.sh", "755"],
        ["hello.txt", "644"],
        ["true", "755"]
      ])
    end
  end
end
