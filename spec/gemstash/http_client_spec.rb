require "spec_helper"

describe Gemstash::HTTPClient do
  before(:all) do
    @server = SimpleServer.new("localhost")
    @other_server = SimpleServer.new("127.0.0.1")
    @server.mount_message("/simple_fetch", "Simple fetch results")
    @server.mount_message("/nested/fetch", "Nested fetch results")
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
      Gemstash::HTTPClient.for(Gemstash::Upstream.new(@server.url))
    end

    context "with a valid url" do
      it "returns the body of the result" do
        expect(http_client.get("simple_fetch")).to eq("Simple fetch results")
      end
    end

    context "with an upstream that includes a path" do
      let(:http_client) do
        Gemstash::HTTPClient.for(Gemstash::Upstream.new("#{@server.url}/nested"))
      end

      it "returns the body of the result" do
        expect(http_client.get("fetch")).to eq("Nested fetch results")
      end
    end

    context "with a valid redirect" do
      it "returns the body of the result after the redirect" do
        expect(http_client.get("redirect")).to eq("Simple fetch results")
      end
    end

    context "with a redirect to a different server" do
      it "returns the body of the result after the redirects" do
        expect(http_client.get("other_redirect")).to eq("Simple fetch results")
      end
    end

    context "with a url that returns a 500" do
      it "throws an error" do
        expect { http_client.get("error") }.to raise_error do |error|
          expect(error).to be_a(Gemstash::WebError)
          expect(error.message).to eq("Error result")
          expect(error.code).to eq(500)
        end
      end
    end

    context "with a url that returns a 404" do
      it "throws an error" do
        expect { http_client.get("missing") }.to raise_error do |error|
          expect(error).to be_a(Gemstash::WebError)
          expect(error.message).to eq("Missing value")
          expect(error.code).to eq(404)
        end
      end
    end

    context "with a stubbed faraday client" do
      let(:stubs) { Faraday::Adapter::Test::Stubs.new }
      let(:faraday_client) { Faraday.new {|builder| builder.adapter(:test, stubs) } }

      context "with a client that specifies a user agent" do
        let(:http_client) do
          Gemstash::HTTPClient.new(faraday_client,
            user_agent: "my-agent 6.6.6")
        end

        it "forwards the user agent to the remote server" do
          stubs.get("/gems/rack", "User-Agent" => "my-agent 6.6.6") do
            [200, { "CONTENT-TYPE" => "octet/stream" }, "zapatito"]
          end
          http_client.get("gems/rack")
          stubs.verify_stubbed_calls
        end
      end

      context "with a simple client" do
        let(:http_client) { Gemstash::HTTPClient.new(faraday_client) }
        let(:default_user_agent) { "Gemstash/#{Gemstash::VERSION}" }

        it "forwards the default user agent to the remote server" do
          stubs.get("/gems/rack", "User-Agent" => default_user_agent) do
            [200, { "CONTENT-TYPE" => "octet/stream" }, "zapatito"]
          end
          http_client.get("gems/rack")
          stubs.verify_stubbed_calls
        end

        it "handles a connection failed error correctly" do
          stubs.get("/gems/rack", "User-Agent" => default_user_agent) do
            raise Faraday::ConnectionFailed, "I don't like your DNS query!"
          end
          expect { http_client.get("/gems/rack") }.to raise_error do |error|
            expect(error).to be_a(Gemstash::ConnectionError)
            expect(error.message).to eq("I don't like your DNS query!")
            expect(error.code).to eq(502)
          end
        end

        it "retries 3 times on connection error" do
          exceptions = [Faraday::ConnectionFailed, Faraday::ConnectionFailed]
          stubs.get("/gems/rack", "User-Agent" => default_user_agent) do
            if exceptions.empty?
              [200, { "CONTENT-TYPE" => "octet/stream" }, "zapatito"]
            else
              raise exceptions.pop, "I don't like your DNS query!"
            end
          end
          expect(http_client.get("/gems/rack")).to eq("zapatito")
          expect(exceptions).to be_empty
        end

        context "with a block to store the headers" do
          it "throws an error" do
            stubs.get("/gems/rack") { [200, { "CONTENT-TYPE" => "octet/stream" }, "zapatito"] }

            body_result = nil
            headers_result = nil

            http_client.get("gems/rack") do |body, headers|
              body_result = body
              headers_result = headers
            end

            expect(body_result).to eq("zapatito")
            expect(headers_result).to eq("CONTENT-TYPE" => "octet/stream")
          end
        end
      end
    end
  end
end
