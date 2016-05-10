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
