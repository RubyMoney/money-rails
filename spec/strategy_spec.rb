require "spec_helper"
require "rack/test"
require "gemstash/strategy"
require "gemstash/storage"

describe Gemstash::CachingStrategy do
  include Rack::Test::Methods

  before do
    @gem_folder = Dir.mktmpdir
  end

  after do
    FileUtils.remove_entry @gem_folder
  end

  let(:storage) { Gemstash::GemStorage.new(@gem_folder) }
  let(:caching_strategy) { Gemstash::CachingStrategy.new(storage: storage) }
  let(:app) { Gemstash::Web.new(gem_strategy: caching_strategy) }

  it "fetchs the gem file, stores, and serves it" do
    get "/gems/rack"
    expect(last_response.body).to eq("zapatito")
    expect(last_response.header["CONTENT-TYPE"]).to eq("octet/stream")
    expect(storage.get("rack")).to exist
  end
end
