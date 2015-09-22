require "spec_helper"
require "gemstash/storage"

describe Gemstash::GemStorage do
  it "Fails to build with an invalid path" do
    invalid_folder = Dir.mktmpdir
    FileUtils.remove_entry invalid_folder
    expect { Gemstash::GemStorage.new(invalid_folder) }.to(
      raise_error(/Folder #{invalid_folder} does not exist or is not writable/)
    )
  end

  # context "with a valid gem folder" do

  #   before do
  #     @gem_folder = Dir.mktmpdir
  #   end

  #   let(:storage) { Gemstash::GemStorage.new(@gem_folder) }
  #   let(:gem_name) { "my_gem-1.8.1.gem" }
  #   let(:gem_headers) { Hash.new("CONTENT-TYPE" => "octet/stream") }
  #   let(:gem_content) { "sentinel content" }

  #   after do
  #     FileUtils.remove_entry @gem_folder
  #   end

  #   it "returns a valid non-existing gem with a new gem" do
  #     expect(storage.get(gem_name)).not_to exist
  #   end

  #   it "can retrieve a stored gem by name including headers and the content" do
  #     storage.get(gem_name).save(gem_headers, gem_content)
  #     cached_gem = storage.get(gem_name)
  #     expect(cached_gem.content).to eq(gem_content)
  #     expect(cached_gem.headers).to eq(gem_headers)
  #   end

  #   it "can replace the content of the gem" do
  #     storage.get(gem_name).save(gem_headers, gem_content)
  #     storage.get(gem_name).save(gem_headers, "new content")
  #     cached_gem = storage.get(gem_name)
  #     expect(cached_gem.content).to eq("new content")
  #     expect(cached_gem.headers).to eq(gem_headers)
  #   end
  # end
end
