describe "split_dir" do
  let(:binary) { Pathname(__dir__)+"../bin/split_dir" }

  it "splits directories with a lot of files" do
    MockUnix.new do |path|
      FileUtils.mkdir_p "test"
      (1..1207).each do |i|
        FileUtils.touch("test/%04d.txt" % i)
      end
      system "#{binary} test"
      expect(path).to have_content([
        "test-1",
        "test-2",
        "test-3",
        "test-4",
        "test-5",
        "test-6",
        "test-7",
        (   1.. 172).map{|i| "test-1/%04d.txt" % i },
        ( 173.. 344).map{|i| "test-2/%04d.txt" % i },
        ( 345.. 517).map{|i| "test-3/%04d.txt" % i },
        ( 518.. 689).map{|i| "test-4/%04d.txt" % i },
        ( 690.. 862).map{|i| "test-5/%04d.txt" % i },
        ( 863..1034).map{|i| "test-6/%04d.txt" % i },
        (1035..1207).map{|i| "test-7/%04d.txt" % i },
      ].flatten)
    end
  end
end
