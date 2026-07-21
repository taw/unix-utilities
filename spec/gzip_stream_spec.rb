require "stringio"

# bin/gzip_stream calls gzip_stream(STDIN, STDOUT, 1) when loaded,
# so eval just the definition to be able to test the function itself
eval (Pathname(__dir__)+"../bin/gzip_stream").read.sub(/^gzip_stream\(STDIN.*\n/, "")

describe "gzip_stream" do
  # To verify that plain gzip doesn't work for it:
  # let(:binary) { "gzip" }
  let(:binary) { Pathname(__dir__)+"../bin/gzip_stream" }

  # Runs gzip_stream on a pipe, yielding the write end and its flusher thread
  def with_gzip_stream(flush_freq)
    reader, writer = IO.pipe
    other_threads = Thread.list
    main = Thread.new{ gzip_stream(reader, StringIO.new("".b), flush_freq) }
    sleep 0.05
    flusher = (Thread.list - other_threads - [main]).first
    flusher.report_on_exception = false
    yield writer, flusher
  ensure
    writer.close unless writer.closed?
    main.join(2)
  end

  def read_available(fh)
    fh.read_nonblock(10_000)
  rescue IO::WaitReadable
    ""
  end

  it "gzips" do
    IO.popen("#{binary} | zcat", "r+") do |fh|
      fh.puts *(1..1000)
      fh.close_write
      expect(fh.readlines).to eq((1..1000).map{|x| "#{x}\n"})
    end
  end

  it "doesn't wait for end of input" do
    IO.popen("#{binary}", "r+") do |fh|
      fh.puts *(1..1000)
      sleep 2
      a = fh.read_nonblock(10_000)
      fh.close_write
      b = fh.read
      # Data
      expect(a.size).to be_between(1750, 1900)
      # Just finalization mark
      expect(b.size).to eq(9)
    end
  end

  it "keeps flushing input which arrives after the first flush" do
    IO.popen("#{binary}", "r+") do |fh|
      fh.puts "first"
      sleep 2.5
      expect(read_available(fh)).to_not be_empty
      # Idle interval, with the first batch already flushed
      sleep 1.5
      fh.puts "second"
      sleep 2.5
      expect(read_available(fh)).to_not be_empty
      fh.close_write
    end
  end

  it "flusher survives idle intervals" do
    with_gzip_stream(0.2) do |writer, flusher|
      writer.puts "hello"
      # First tick flushes, later ones have nothing to flush
      sleep 0.7
      expect{ flusher.join(0.1) }.to_not raise_error
      expect(flusher).to be_alive
    end
  end

  it "flusher exits cleanly once the stream is closed" do
    with_gzip_stream(0.2) do |writer, flusher|
      writer.close
      sleep 0.7
      expect{ flusher.join(0.1) }.to_not raise_error
      expect(flusher).to_not be_alive
    end
  end
end
