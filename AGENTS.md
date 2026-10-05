# AGENTS.md

Small standalone Unix utilities meant to be dropped into `~/bin`. Primary target is macOS; most also run on Linux (CI is Ubuntu).

## Layout

- `bin/<name>` – one self-contained executable per utility, no extension. Nearly all are Ruby (`#!/usr/bin/env ruby`); `rename` is Larry Wall's Perl script, bundled as-is.
- `spec/<name>_spec.rb` – RSpec spec for each utility. `spec/coverage_spec.rb` marks any `bin/` file without a spec as pending.
- `spec/<name>/` – fixtures for a utility (e.g. `spec/unall/`, `spec/toutf8/`).
- `spec/spec_helper.rb` – `osx?` and `have_command?` helpers (usable in `describe` bodies and examples), `MockUnix` (temp dir + fake commands on `PATH` with call traces) and the `have_content` matcher.
- `spec/mock_network.rb` + `spec/vcr/network.yml` – VCR/WebMock for network utilities. Re-record with `RECORD=1`.
- `README.md` – one section per utility, kept in alphabetical order.
- `.semaphore/semaphore.yml` – CI (Ubuntu, Ruby 4.0.x, `bundle exec rspec`).

## Commands

```
bundle install
bundle exec rspec                    # full suite (also: rake)
bundle exec rspec spec/swap_spec.rb  # one utility
```

## Conventions

- Keep each script self-contained; shared code between scripts is not a thing here. Gems come from the `Gemfile` (add new ones there; note `pstore` is no longer stdlib on Ruby 4).
- Prefer Ruby stdlib/gems over shelling out (`FileUtils.mv`, `File.chmod`, `Zlib`, `ruby-mp3info`, `nokogiri`, `Net::HTTP` …). Only shell out when the external tool is the point (ffmpeg, 7z, yt-dlp, etc.), and then use array-form `system`/`Open3` or `Shellwords` – never interpolate unescaped paths.
- Bad usage: print `Usage: #{$0} ...` to STDERR and `exit 1`. Per-file problems: warn to STDERR (`<file>: <reason>, skipping`) and carry on.
- Handle edge cases explicitly: empty input, symlinks (including broken ones), files with spaces/odd characters, nested paths, cross-device moves, `EPIPE`/`EINTR`. Refuse likely mistakes (e.g. overlapping dirs in `dedup_files`) rather than guessing.
- Output should be deterministic (stable ordering) so it's testable.
- Match existing style: 2-space indent, double-quoted strings, minimal comments explaining *why* only.

## Tests

- Every bug fix or behaviour change gets a spec. New utilities need a spec, a README section (alphabetical), and an executable bit.
- Specs run the real script as a subprocess (`IO.popen`, `Open3`, backticks) against `Pathname(__dir__)+"../bin/<name>"`.
- Use `MockUnix.new { |env| env.mock_command(...) }` to stub external programs and assert on `env.command_trace`.
- Guard platform/tool-specific tests: `skip: !have_command?("zstd")`, `skip unless osx?`. Prefer committed fixtures over requiring a tool to build them (e.g. `spec/unall/foo.cpio`).
- Avoid timing flakiness: don't assume `sleep N` takes exactly N, don't race on very short inputs.

## Commits

Short imperative-ish one-line messages describing the change (e.g. "Don't shell out for mv", "Fixed webman shellescape bug"). One logical change per commit.
