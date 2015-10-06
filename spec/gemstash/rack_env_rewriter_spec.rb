require "spec_helper"
require "cgi"

describe Gemstash::RackEnvRewriter do
  context "with just a prefix to drop" do
    let(:env) do
      {
        "REQUEST_URI" => "/private/some/path?arg=abc",
        "PATH_INFO" => "/private/some/path"
      }
    end

    it "rewrites the URI" do
      rewriter = Gemstash::RackEnvRewriter.new(%r{\A/private})
      context = rewriter.for(env)
      expect(context.matches?).to be_truthy
      context.rewrite
      expect(context.captures).to be_empty
      expect(env["REQUEST_URI"]).to eq("/some/path?arg=abc")
      expect(env["PATH_INFO"]).to eq("/some/path")
    end

    it "doesn't do anything if there is no match" do
      rewriter = Gemstash::RackEnvRewriter.new(%r{\A/other})
      context = rewriter.for(env)
      expect(context.matches?).to be_falsey
      expect { context.rewrite }.to raise_error(RuntimeError)
      expect { context.captures }.to raise_error(RuntimeError)
      expect(env["REQUEST_URI"]).to eq("/private/some/path?arg=abc")
      expect(env["PATH_INFO"]).to eq("/private/some/path")
    end
  end

  context "with a parameter to extract" do
    let(:upstream_url) { "https://some.gemsite.com" }
    let(:escaped_upstream_url) { CGI.escape(upstream_url) }

    let(:env) do
      {
        "REQUEST_URI" => "/upstream/#{escaped_upstream_url}/some/path?arg=abc",
        "PATH_INFO" => "/upstream/#{escaped_upstream_url}/some/path"
      }
    end

    it "captures the parameter and rewrites the URI" do
      rewriter = Gemstash::RackEnvRewriter.new(%r{\A/upstream/(?<upstream_url>[^/]+)})
      context = rewriter.for(env)
      expect(context.matches?).to be_truthy
      context.rewrite
      expect(context.captures["upstream_url"]).to eq(escaped_upstream_url)
      expect(env["REQUEST_URI"]).to eq("/some/path?arg=abc")
      expect(env["PATH_INFO"]).to eq("/some/path")
    end

    it "doesn't do anything if there is no match" do
      rewriter = Gemstash::RackEnvRewriter.new(%r{\A/redirect/(?<upstream_url>[^/]+)})
      context = rewriter.for(env)
      expect(context.matches?).to be_falsey
      expect { context.rewrite }.to raise_error(RuntimeError)
      expect { context.captures }.to raise_error(RuntimeError)
      expect(env["REQUEST_URI"]).to eq("/upstream/#{escaped_upstream_url}/some/path?arg=abc")
      expect(env["PATH_INFO"]).to eq("/upstream/#{escaped_upstream_url}/some/path")
    end
  end
end
