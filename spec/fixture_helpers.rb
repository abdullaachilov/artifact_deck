require 'json'

def fixture_file_path(filename)
  File.join(ArtifactDeck.root, "spec/fixtures/#{filename}")
end

def read_fixture_file(filename)
  File.read fixture_file_path(filename)
end

def json_fixture_file(filename)
  JSON.parse(read_fixture_file(filename), symbolize_names: true)
end
