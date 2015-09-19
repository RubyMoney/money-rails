require "spec_helper"
require "rack/test"

describe Gemstash::Web do
  include Rack::Test::Methods
  let(:app) { Gemstash::Web.new }

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
      get request

      expect(last_response).to redirect_to("https://www.rubygems.org")
    end
  end

  context "GET /api/v1/dependencies" do
    let(:request) { "/api/v1/dependencies" }

    context "there are no gems" do
      it "returns an empty string" do
        get request

        expect(last_response).to be_ok
        expect(last_response.body).to eq("")
      end
    end

    context "there are gems" do
      before do
        Gemstash::Env.memcached_client.set("deps/v1/rack", [rack])
      end

      it "returns a marshal dump" do
        get "#{request}?gems=rack"

        expect(last_response).to be_ok
        expect(Marshal.load(last_response.body)).to eq([rack])
      end
    end

    context "there are too many gems" do
      let(:gems) { 201.times.map {|i| "gem-#{i}" }.join(",") }

      it "returns a 422" do
        get "#{request}?gems=#{gems}"

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
        get request

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
        Gemstash::Env.memcached_client.set("deps/v1/rack", [rack])
      end

      it "returns a marshal dump" do
        result = [{
          "name"         => "rack",
          "number"       => "1.0.0",
          "platform"     => "ruby",
          "dependencies" => []
        }]

        get "#{request}?gems=rack"

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

        get "#{request}?gems=#{gems}"

        expect(last_response).not_to be_ok
        expect(last_response.body).to eq(error)
      end
    end
  end
end
