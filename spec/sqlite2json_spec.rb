require "sqlite3"
require "json"

describe "sqlite2json" do
  let(:binary) { Pathname(__dir__)+"../bin/sqlite2json" }

  it "dumps every table as a json file" do
    MockUnix.new do |path|
      db = SQLite3::Database.new("test.sqlite")
      db.execute "CREATE TABLE items(id INTEGER PRIMARY KEY, name TEXT)"
      db.execute "INSERT INTO items VALUES (1, 'a'), (2, 'b')"
      db.close
      system "#{binary} test.sqlite out"
      expect(path).to have_content(["test.sqlite", "out", "out/items.json"])
      expect(JSON.parse((path.path+"out/items.json").read)).to eq([
        {"id" => 1, "name" => "a"},
        {"id" => 2, "name" => "b"},
      ])
    end
  end

  it "skips sqlite internal tables" do
    MockUnix.new do |path|
      db = SQLite3::Database.new("test.sqlite")
      db.execute "CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)"
      db.execute "INSERT INTO items(name) VALUES ('a'), ('b')"
      db.execute "CREATE INDEX items_name ON items(name)"
      db.execute "ANALYZE"
      db.close
      system "#{binary} test.sqlite out"
      expect(path).to have_content(["test.sqlite", "out", "out/items.json"])
    end
  end
end
