require "pry"
require "pathname"
require "tmpdir"
require "fileutils"

class MockUnix
  attr_reader :path
  def initialize
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        @path = Pathname(dir)
        yield(self)
      end
    end
  end
end

RSpec::Matchers.define :have_content do |expected|
  match do |env|
    actual = env.path.find.map{|x| x.relative_path_from(env.path) }.select{|x| x != Pathname(".")}.map(&:to_s)
    expected.sort == actual.sort
  end
end
