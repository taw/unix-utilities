require "pathname"
require "tmpdir"
require "fileutils"

def Dir.chtmpdir
  Dir.mktmpdir do |dir|
    Dir.chdir(dir) do
      yield(Pathname(dir))
    end
  end
end

class Pathname
  # Helper for testing
  def descendants
    find.map{|x| x.relative_path_from(self) }.select{|x| x != Pathname(".")}.map(&:to_s)
  end
end
