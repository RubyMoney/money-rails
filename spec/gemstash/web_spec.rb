# frozen_string_literal: true

require "spec_helper"
require "faraday"
require "fileutils"
require "rack/test"

describe Gemstash::Web do
  include Rack::Test::Methods

  let(:http_client_builder) do
    #:nodoc:
    class StubHttpBuilder
      def for(server_url, timeout = 20)
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.get("/gems/rack") { [200, { "CONTENT-TYPE" => "octet/stream" }, "zapatito"] }
          stub.get("/gems/rack-1.0.0.gem") { [200, { "CONTENT-TYPE" => "octet/stream" }, "zapatito-1.0.0"] }
          stub.get("/gems/rack-1.1.0.gem") { [200, { "CONTENT-TYPE" => "octet/stream" }, "zapatito-1.1.0"] }
          stub.get("/quick/Marshal.4.8/rack.gemspec.rz") { [200, { "CONTENT-TYPE" => "octet/stream" }, "specatito"] }
          stub.get("/quick/Marshal.4.8/rack-1.0.0.gemspec.rz") do
            [200, { "CONTENT-TYPE" => "octet/stream" }, "specatito-1.0.0"]
          end
          stub.get("/quick/Marshal.4.8/rack-1.1.0.gemspec.rz") do
            [200, { "CONTENT-TYPE" => "octet/stream" }, "specatito-1.1.0"]
          end
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
  let(:upstream) { "https://rubygems.org" }
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

      expect(last_response).to redirect_to("https://rubygems.org")
    end
  end

  context "GET /versions" do
    let(:request) { "/versions" }

    context "with https://rubygems.org upstream" do
      it "redirects to https://index.rubygems.org" do
        get request, {}, rack_env

        expect(last_response).to redirect_to("https://index.rubygems.org/versions")
      end
    end

    context "with a non https://rubygems.org upstream" do
      let(:upstream) { "https://private-gem-server.net" }

      it "redirects to the same upstream" do
        get request, {}, rack_env

        expect(last_response).to redirect_to("#{upstream}/versions")
      end
    end
  end

  context "GET /info/*" do
    let(:request) { "/info/some-gem" }

    context "with https://rubygems.org upstream" do
      it "redirects to https://index.rubygems.org" do
        get request, {}, rack_env

        expect(last_response).to redirect_to("https://index.rubygems.org/info/some-gem")
      end
    end

    context "with a non https://rubygems.org upstream" do
      let(:upstream) { "https://private-gem-server.net" }

      it "redirects to the same upstream" do
        get request, {}, rack_env

        expect(last_response).to redirect_to("#{upstream}/info/some-gem")
      end
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
      let(:gems) { Array.new(201) {|i| "gem-#{i}" }.join(",") }

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
      let(:gems) { Array.new(201) {|i| "gem-#{i}" }.join(",") }

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

      it "fetches the gem file, stores, and serves it" do
        get "/gems/rack", {}, rack_env
        expect(last_response.body).to eq("zapatito")
        expect(last_response.header["CONTENT-TYPE"]).to eq("octet/stream")
        expect(storage.resource("rack").exist?(:gem)).to be_truthy
      end

      it "keeps the upstream and full gem name in the properties" do
        get "/gems/rack-1.0.0.gem", {}, rack_env
        properties = storage.resource("rack-1.0.0").properties
        expect(properties[:upstream]).to eq(upstream.to_s)
        expect(properties[:gem_name]).to eq("rack-1.0.0")
      end

      it "keeps headers for specs that have been previously fetched" do
        get "/quick/Marshal.4.8/rack.gemspec.rz", {}, rack_env
        get "/gems/rack", {}, rack_env
        expect(storage.resource("rack").properties[:headers][:spec]).to be
        expect(storage.resource("rack").properties[:headers][:gem]).to be
      end

      it "indexes the cached gem" do
        get "/gems/rack", {}, rack_env
        db_upstream = Gemstash::DB::Upstream[uri: upstream.to_s]
        expect(db_upstream).to be
        expect(Gemstash::DB::CachedRubygem[upstream_id: db_upstream.id, name: "rack", resource_type: "gem"]).to be
      end

      it "indexes specs of different versions separately" do
        get "/gems/rack-1.0.0.gem", {}, rack_env
        get "/gems/rack-1.1.0.gem", {}, rack_env
        db_upstream = Gemstash::DB::Upstream[uri: upstream.to_s]
        expect(db_upstream).to be
        expect(Gemstash::DB::CachedRubygem[upstream_id: db_upstream.id, name: "rack-1.0.0", resource_type: "gem"]).to be
        expect(Gemstash::DB::CachedRubygem[upstream_id: db_upstream.id, name: "rack-1.1.0", resource_type: "gem"]).to be
      end

      it "can be called multiple times without error" do
        get "/gems/rack", {}, rack_env
        get "/gems/rack", {}, rack_env
      end

      it "can be called after the gem has been deleted" do
        get "/gems/rack", {}, rack_env
        storage.resource("rack").delete(:gem)
        expect(storage.resource("rack").exist?(:gem)).to be_falsey
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

      it "fetches the marshalled gemspec, stores, and serves it" do
        get "/quick/Marshal.4.8/rack.gemspec.rz", {}, rack_env
        expect(last_response.body).to eq("specatito")
        expect(last_response.header["CONTENT-TYPE"]).to eq("octet/stream")
        expect(storage.resource("rack").exist?(:spec)).to be_truthy
      end

      it "keeps the upstream and full gem name in the properties" do
        get "/quick/Marshal.4.8/rack-1.0.0.gemspec.rz", {}, rack_env
        properties = storage.resource("rack-1.0.0").properties
        expect(properties[:upstream]).to eq(upstream.to_s)
        expect(properties[:gem_name]).to eq("rack-1.0.0")
      end

      it "keeps headers for gems that have been previously fetched" do
        get "/gems/rack", {}, rack_env
        get "/quick/Marshal.4.8/rack.gemspec.rz", {}, rack_env
        expect(storage.resource("rack").properties[:headers][:gem]).to be
        expect(storage.resource("rack").properties[:headers][:spec]).to be
      end

      it "indexes the cached spec" do
        get "/quick/Marshal.4.8/rack.gemspec.rz", {}, rack_env
        db_upstream = Gemstash::DB::Upstream[uri: upstream.to_s]
        expect(db_upstream).to be
        expect(Gemstash::DB::CachedRubygem[upstream_id: db_upstream.id, name: "rack", resource_type: "spec"]).to be
      end

      it "indexes specs of different versions separately" do
        get "/quick/Marshal.4.8/rack-1.0.0.gemspec.rz", {}, rack_env
        get "/quick/Marshal.4.8/rack-1.1.0.gemspec.rz", {}, rack_env
        db_upstream = Gemstash::DB::Upstream[uri: upstream.to_s]
        expect(db_upstream).to be
        expect(Gemstash::DB::CachedRubygem[upstream_id: db_upstream.id, name: "rack-1.0.0", resource_type: "spec"]).to be
        expect(Gemstash::DB::CachedRubygem[upstream_id: db_upstream.id, name: "rack-1.1.0", resource_type: "spec"]).to be
      end

      it "can be called multiple times without error" do
        get "/quick/Marshal.4.8/rack.gemspec.rz", {}, rack_env
        get "/quick/Marshal.4.8/rack.gemspec.rz", {}, rack_env
      end

      it "can be called after the spec has been deleted" do
        get "/quick/Marshal.4.8/rack.gemspec.rz", {}, rack_env
        storage.resource("rack").delete(:spec)
        expect(storage.resource("rack").exist?(:spec)).to be_falsey
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

  context "POST /api/v1/gems" do
    let(:gem_source) { Gemstash::GemSource::PrivateSource }
    let(:auth_key) { "auth-key" }
    let(:env) { rack_env.merge("CONTENT_TYPE" => "application/octet-stream", "HTTP_AUTHORIZATION" => auth_key) }

    before do
      Gemstash::Authorization.authorize(auth_key, "all")
    end

    it "returns 200 on a successful push" do
      post "/api/v1/gems", read_gem("example", "0.1.0"), env
      expect(last_response).to be_ok
      expect(last_response.status).to eq(200)
    end

    it "returns a 422 when gem already exists" do
      post "/api/v1/gems", read_gem("example", "0.1.0"), env
      expect(last_response).to be_ok

      post "/api/v1/gems", read_gem("example", "0.1.0"), env
      expect(last_response).to_not be_ok
      expect(last_response.status).to eq(422)
      expect(JSON.parse(last_response.body)).to eq("error" => "Version already exists", "code" => 422)
    end
  end
end
