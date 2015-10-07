require "spec_helper"

describe Gemstash::WebHelper do
  describe ".url" do
    let(:server_url) { "https://www.rubygems.org" }
    let(:helper) { Gemstash::WebHelper.new(server_url: server_url) }

    context "with nothing provided" do
      it "returns the server url" do
        expect(helper.url).to eq("https://www.rubygems.org")
        expect(helper.url(nil, "")).to eq("https://www.rubygems.org")
        expect(helper.url("", "")).to eq("https://www.rubygems.org")
      end
    end

    context "with just a query string provided" do
      it "returns the url" do
        expect(helper.url(nil, "abc=123")).to eq("https://www.rubygems.org?abc=123")
      end
    end

    context "with just a path provided" do
      it "returns the url" do
        expect(helper.url("/path/somewhere")).to eq("https://www.rubygems.org/path/somewhere")
      end
    end

    context "with just a path and query string provided" do
      it "returns the url" do
        expect(helper.url("/path/somewhere", "abc=123")).to eq("https://www.rubygems.org/path/somewhere?abc=123")
      end
    end
  end
end

describe Gemstash::HTTPClient do
  before(:all) do
    @server = SimpleServer.new("localhost")
    @other_server = SimpleServer.new("127.0.0.1")
    @server.mount_message("/simple_fetch", "Simple fetch results")
    @server.mount_message("/error", "Error result", 500)
    @server.mount_message("/missing", "Missing value", 404)
    @server.mount_redirect("/redirect", "/simple_fetch")
    @server.mount_redirect("/other_redirect", "#{@other_server.url}/redirect")
    @other_server.mount_redirect("/redirect", "#{@server.url}/simple_fetch")
    @server.start
    @other_server.start
  end

  after(:all) do
    @server.stop
    @other_server.stop
  end

  describe ".get" do
    let(:http_client) do
      Gemstash::HTTPClient.for(@server.url)
    end

    context "with a valid url" do
      it "returns the body of the result" do
        expect(http_client.get("/simple_fetch")).to eq("Simple fetch results")
      end
    end

    context "with a valid redirect" do
      it "returns the body of the result after the redirect" do
        expect(http_client.get("/redirect")).to eq("Simple fetch results")
      end
    end

    context "with a redirect to a different server" do
      it "returns the body of the result after the redirects" do
        expect(http_client.get("/other_redirect")).to eq("Simple fetch results")
      end
    end

    context "with a url that returns a 500" do
      it "throws an error" do
        expect { http_client.get("/error") }.to raise_error do |error|
          expect(error).to be_a(Gemstash::WebError)
          expect(error.message).to eq("Error result")
          expect(error.code).to eq(500)
        end
      end
    end

    context "with a url that returns a 404" do
      it "throws an error" do
        expect { http_client.get("/missing") }.to raise_error do |error|
          expect(error).to be_a(Gemstash::WebError)
          expect(error.message).to eq("Missing value")
          expect(error.code).to eq(404)
        end
      end
    end

    context "with a block to store the headers" do
      let(:faraday_client) do
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.get("/gems/rack") { [200, { "CONTENT-TYPE" => "octet/stream" }, "zapatito"] }
        end
        Faraday.new {|builder| builder.adapter(:test, stubs) }
      end

      let(:http_client) { Gemstash::HTTPClient.new(faraday_client) }

      it "throws an error" do
        body_result = nil
        headers_result = nil

        http_client.get("/gems/rack") do |body, headers|
          body_result = body
          headers_result = headers
        end

        expect(body_result).to eq("zapatito")
        expect(headers_result).to eq("CONTENT-TYPE" => "octet/stream")
      end
    end
  end
end
