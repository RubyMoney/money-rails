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

  context "with a valid request and stack" do
    let(:gem_fetcher) do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get("/gems/rack") { [200, { "CONTENT-TYPE" => "octet/stream" }, "zapatito"] }
      end
      Gemstash::GemFetcher.new(http_client: Faraday.new {|builder| builder.adapter(:test, stubs) })
    end

    let(:storage) { Gemstash::GemStorage.new(@gem_folder) }
    let(:caching_strategy) { Gemstash::CachingStrategy.new(storage: storage, gem_fetcher: gem_fetcher) }
    let(:app) { Gemstash::Web.new(gem_strategy: caching_strategy) }

    it "fetchs the gem file, stores, and serves it" do
      get "/gems/rack"
      expect(last_response.body).to eq("zapatito")
      expect(last_response.header["CONTENT-TYPE"]).to eq("octet/stream")
      expect(storage.get("rack")).to exist
    end
  end
end

describe Gemstash::GemFetcher do
  it "builds" do
    expect(Gemstash::GemFetcher.new).not_to be_nil
  end

  context "with a valid fetcher" do
    let(:http_client) do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get("/gems/rack") { [200, { "CONTENT-TYPE" => "octet/stream" }, "zapatito"] }
        stub.get("/gems/not_available") { [404, {}, ""] }
      end
      Faraday.new {|builder| builder.adapter(:test, stubs) }
    end
    let(:gem_fetcher) { Gemstash::GemFetcher.new(http_client: http_client) }

    it "fetchs a gem by id" do
      expect(gem_fetcher.fetch("rack")).to eq(Gemstash::FetchedGem.new({ "CONTENT-TYPE" => "octet/stream" }, "zapatito"))
    end

    it "fails to find a gem that is not there" do
      expect { gem_fetcher.fetch("not_available") }.to raise_error(/not_available/)
    end
  end
end
