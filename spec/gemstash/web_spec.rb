require "spec_helper"
require "faraday"
require "fileutils"
require "rack/test"

describe Gemstash::Web do
  include Rack::Test::Methods

  let(:http_client_builder) do
    #:nodoc:
    class StubHttpBuilder
      def for(server_url)
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.get("/gems/rack") { [200, { "CONTENT-TYPE" => "octet/stream" }, "zapatito"] }
          stub.get("/quick/Marshal.4.8/rack.gemspec.rz") { [200, { "CONTENT-TYPE" => "octet/stream" }, "specatito"] }
        end
        client = Faraday.new {|builder| builder.adapter(:test, stubs) }
        Gemstash::HTTPClient.new(client)
      end
    end
    StubHttpBuilder.new
  end
  let(:app) do
    Gemstash::Web.new(http_client_builder: http_client_builder,
                      gemstash_env: test_env)
  end
  let(:upstream) { "https://www.rubygems.org" }
  let(:gem_source) { Gemstash::GemSource::RubygemsSource }

  let(:rack_env) do
    {
      "gemstash.gem_source" => gem_source,
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
    context "from the default upstream" do
      let(:current_env) { Gemstash::Env.current }
      let(:upstream) { Gemstash::Upstream.new(current_env.config[:rubygems_url]) }
      let(:storage) { Gemstash::Storage.for("gem_cache").for(upstream.host_id) }

      it "fetchs the gem file, stores, and serves it" do
        get "/gems/rack", {}, rack_env
        expect(last_response.body).to eq("zapatito")
        expect(last_response.header["CONTENT-TYPE"]).to eq("octet/stream")
        expect(storage.resource("rack").exist?(:gem)).to be_truthy
      end
    end

    context "from private gems" do
      let(:gem_source) { Gemstash::GemSource::PrivateSource }
      let(:storage) { Gemstash::Storage.for("private").for("gems") }

      context "with a missing gem" do
        it "halts with 404" do
          get "/gems/unknown-0.1.0.gem", {}, rack_env
          expect(last_response).to_not be_ok
          expect(last_response.status).to eq(404)
          expect(last_response.body).to match(/not found/i)
        end
      end

      context "with a regular gem" do
        before do
          gem_id = insert_rubygem "example"
          insert_version gem_id, "0.1.0"
          storage.resource("example-0.1.0").save({ gem: "Example gem content" }, indexed: true)
        end

        it "fetches the gem contents" do
          get "/gems/example-0.1.0.gem", {}, rack_env
          expect(last_response).to be_ok
          expect(last_response.body).to eq("Example gem content")
        end
      end

      context "with a yanked gem" do
        before do
          gem_id = insert_rubygem "yanked"
          insert_version gem_id, "0.1.0", indexed: false
          storage.resource("yanked-0.1.0").save({ gem: "Example yanked gem content" }, indexed: false)
        end

        it "halts with 403" do
          get "/gems/yanked-0.1.0.gem", {}, rack_env
          expect(last_response).to_not be_ok
          expect(last_response.status).to eq(403)
          expect(last_response.body).to_not eq("Example yanked gem content")
        end
      end
    end
  end

  context "GET /quick/Marshal.4.8/:id" do
    context "from the default upstream" do
      let(:current_env) { Gemstash::Env.current }
      let(:upstream) { Gemstash::Upstream.new(current_env.config[:rubygems_url]) }
      let(:storage) { Gemstash::Storage.for("gem_cache").for(upstream.host_id) }

      it "fetchs the marshalled gemspec, stores, and serves it" do
        get "/quick/Marshal.4.8/rack.gemspec.rz", {}, rack_env
        expect(last_response.body).to eq("specatito")
        expect(last_response.header["CONTENT-TYPE"]).to eq("octet/stream")
        expect(storage.resource("rack").exist?(:spec)).to be_truthy
      end
    end

    context "from private gems" do
      let(:gem_source) { Gemstash::GemSource::PrivateSource }
      let(:storage) { Gemstash::Storage.for("private").for("gems") }

      context "with a missing gem" do
        it "halts with 404" do
          get "/quick/Marshal.4.8/unknown-0.1.0.gemspec.rz", {}, rack_env
          expect(last_response).to_not be_ok
          expect(last_response.status).to eq(404)
          expect(last_response.body).to match(/not found/i)
        end
      end

      context "with a regular gem" do
        before do
          gem_id = insert_rubygem "example"
          insert_version gem_id, "0.1.0"
          storage.resource("example-0.1.0").save({ gem: "Example gem content",
                                                   spec: "Example gemspec content" }, indexed: true)
        end

        it "fetches the spec contents" do
          get "/quick/Marshal.4.8/example-0.1.0.gemspec.rz", {}, rack_env
          expect(last_response).to be_ok
          expect(last_response.body).to eq("Example gemspec content")
        end
      end

      context "with a yanked gem" do
        before do
          gem_id = insert_rubygem "yanked"
          insert_version gem_id, "0.1.0", indexed: false
          storage.resource("yanked-0.1.0").save({ gem: "Example yanked gem content",
                                                  spec: "Example yanked gemspec content" }, indexed: false)
        end

        it "halts with 403" do
          get "/quick/Marshal.4.8/yanked-0.1.0.gemspec.rz", {}, rack_env
          expect(last_response).to_not be_ok
          expect(last_response.status).to eq(403)
          expect(last_response.body).to_not match(/Example yanked gem(spec)? content/)
        end
      end
    end
  end
end
