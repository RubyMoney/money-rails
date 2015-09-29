require "spec_helper"
require "rack/test"

describe Gemstash::CachingStrategy do
  include Rack::Test::Methods

  before do
    @gem_folder = Dir.mktmpdir
  end

  after do
    FileUtils.remove_entry @gem_folder
  end

  context "with a valid request and stack" do
    let(:web_helper) do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get("/gems/rack") { [200, { "CONTENT-TYPE" => "octet/stream" }, "zapatito"] }
      end
      Gemstash::WebHelper.new(http_client: Faraday.new {|builder| builder.adapter(:test, stubs) })
    end

    let(:storage) { Gemstash::GemStorage.new(@gem_folder) }
    let(:caching_strategy) { Gemstash::CachingStrategy.new(storage: storage, web_helper: web_helper) }
    let(:app) { Gemstash::Web.new(gem_strategy: caching_strategy) }

    it "fetchs the gem file, stores, and serves it" do
      get "/gems/rack"
      expect(last_response.body).to eq("zapatito")
      expect(last_response.header["CONTENT-TYPE"]).to eq("octet/stream")
      expect(storage.get("rack")).to exist
    end
  end
end

describe "Gemstash.strategy_from_config" do
  before do
    @gem_folder = Dir.mktmpdir
  end

  after do
    FileUtils.remove_entry @gem_folder
    Gemstash::Env.current.reset
  end

  it "Returns a caching strategy by default" do
    config = Gemstash::Env.current.config
    expect(Gemstash::Strategies.from_config(config)).to be_an_instance_of(Gemstash::CachingStrategy)
  end

  it "Returns a caching strategy when configured so" do
    config = Gemstash::Configuration.new(config: { :strategy => "redirection" })
    expect(Gemstash::Strategies.from_config(config)).to be_an_instance_of(Gemstash::RedirectionStrategy)
  end
end
