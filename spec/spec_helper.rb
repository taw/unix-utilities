require "pry"
require "pathname"
require "tmpdir"
require "fileutils"

class MockUnix
  attr_reader :path
  def initialize
    Dir.mktmpdir do |root_dir|
      Dir.mktmpdir do |bin_dir|
        @bin_path = Pathname(bin_dir)
        @path = Pathname(root_dir)
        @saved_env_path = ENV["PATH"]
        Dir.chdir(@path) do
          begin
            ENV["PATH"] = "#{@bin_path}:#{@saved_env_path}"
            yield(self)
          ensure
            ENV["PATH"] = @saved_env_path
          end
        end
      end
    end
  end

  def mock_command(name)
    cmd_path = @bin_path+name
    cmd_path.open("w", 0755) do |fh|
      fh.puts "#!/usr/bin/env ruby"
      fh.puts "open(#{ command_trace_path('open').to_s.inspect }, 'a'){|fh| fh.puts ARGV.inspect}"
    end
  end

  def command_trace_path(name)
    Pathname((@bin_path+name).to_s+".trace")
  end

  def command_trace(name)
    path = command_trace_path(name)
    if path.exist?
      path.readlines.map{|line| eval(line)}
    else
      []
    end
  end
end

RSpec::Matchers.define :have_content do |expected|
  match do |env|
    actual = env.path.find.map{|x| x.relative_path_from(env.path) }.select{|x| x != Pathname(".")}.map(&:to_s)
    expected.sort == actual.sort
  end
end
