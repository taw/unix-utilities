require "webmock"
require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = Pathname(__dir__) + "vcr"
  config.hook_into :webmock
end

VCR.insert_cassette(
  "network",
  record: ENV["RECORD"] ? :new_episodes : :none
)

at_exit {
  VCR.eject_cassette
}
