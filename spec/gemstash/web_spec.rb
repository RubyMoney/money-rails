require "spec_helper"
require "rack/test"
require "fileutils"

describe Gemstash::Web do
  include Rack::Test::Methods
  let(:app) { Gemstash::Web.new(gemstash_env: test_env) }
  let(:upstream) { "https://www.rubygems.org" }

  let(:rack_env) do
    {
      "gemstash.gem_source" => Gemstash::GemSource::RubygemsSource,
      "gemstash.upstream" => upstream
    }
  end

  let(:rack) do
    {
      :name         => "rack",
      :number       => "1.0.0",
      :platform     => "ruby",
      :dependencies => []
    }
  end

  context "GET /" do
    let(:request) { "/" }

    it "redirects to rubygems.org" do
      get request, {}, rack_env

      expect(last_response).to redirect_to("https://www.rubygems.org")
    end
  end

  context "GET /api/v1/dependencies" do
    let(:request) { "/api/v1/dependencies" }

    context "there are no gems" do
      it "returns an empty string" do
        get request, {}, rack_env

        expect(last_response).to be_ok
        expect(last_response.body).to eq("")
      end
    end

    context "there are gems" do
      before do
        Gemstash::Env.current.cache.set_dependency("upstream/#{upstream}", "rack", [rack])
      end

      it "returns a marshal dump" do
        get "#{request}?gems=rack", {}, rack_env

        expect(last_response).to be_ok
        expect(Marshal.load(last_response.body)).to eq([rack])
      end
    end

    context "there are too many gems" do
      let(:gems) { 201.times.map {|i| "gem-#{i}" }.join(",") }

      it "returns a 422" do
        get "#{request}?gems=#{gems}", {}, rack_env

        expect(last_response).not_to be_ok
        expect(last_response.body).
          to eq("Too many gems (use --full-index instead)")
      end
    end
  end

  context "GET /api/v1/dependencies.json" do
    let(:request) { "/api/v1/dependencies.json" }

    context "there are no gems" do
      it "returns an empty string" do
        get request, {}, rack_env

        expect(last_response).to be_ok
        expect(last_response.body).to eq("")
      end
    end

    context "there are gems" do
      let(:rack) do
        {
          :name         => "rack",
          :number       => "1.0.0",
          :platform     => "ruby",
          :dependencies => []
        }
      end

      before do
        Gemstash::Env.current.cache.set_dependency("upstream/#{upstream}", "rack", [rack])
      end

      it "returns a marshal dump" do
        result = [{
          "name"         => "rack",
          "number"       => "1.0.0",
          "platform"     => "ruby",
          "dependencies" => []
        }]

        get "#{request}?gems=rack", {}, rack_env

        expect(last_response).to be_ok
        expect(JSON.parse(last_response.body)).to eq(result)
      end
    end

    context "there are too many gems" do
      let(:gems) { 201.times.map {|i| "gem-#{i}" }.join(",") }

      it "returns a 422" do
        error = {
          "error" => "Too many gems (use --full-index instead)",
          "code"  => 422
        }.to_json

        get "#{request}?gems=#{gems}", {}, rack_env

        expect(last_response).not_to be_ok
        expect(last_response.body).to eq(error)
      end
    end
  end

  context "GET /gems/:id" do
    before do
      @gem_folder = Dir.mktmpdir
    end

    after do
      FileUtils.remove_entry @gem_folder
    end

    let(:web_helper) do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get("/gems/rack") { [200, { "CONTENT-TYPE" => "octet/stream" }, "zapatito"] }
      end
      Gemstash::WebHelper.new(http_client: Faraday.new {|builder| builder.adapter(:test, stubs) })
    end

    let(:storage) { Gemstash::Storage.new(@gem_folder) }

    it "fetchs the gem file, stores, and serves it" do
      allow_any_instance_of(Gemstash::GemSource::RubygemsSource).to receive(:web_helper).and_return(web_helper)
      allow_any_instance_of(Gemstash::GemSource::RubygemsSource).to receive(:storage).and_return(storage)
      get "/gems/rack", {}, rack_env
      expect(last_response.body).to eq("zapatito")
      expect(last_response.header["CONTENT-TYPE"]).to eq("octet/stream")
      expect(storage.resource("rack")).to exist
    end
  end
end
