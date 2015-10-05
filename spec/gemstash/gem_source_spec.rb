require "spec_helper"
require "cgi"

describe Gemstash::GemSource::RackEnvRewriter do
  context "with just a prefix to drop" do
    let(:env) do
      {
        "REQUEST_URI" => "/private/some/path?arg=abc",
        "PATH_INFO" => "/private/some/path"
      }
    end

    it "rewrites the URI" do
      rewriter = Gemstash::GemSource::RackEnvRewriter.new(%r{\A/private})
      context = rewriter.for(env)
      expect(context.matches?).to be_truthy
      context.rewrite
      expect(context.params).to match_array([])
      expect(env["REQUEST_URI"]).to eq("/some/path?arg=abc")
      expect(env["PATH_INFO"]).to eq("/some/path")
    end

    it "doesn't do anything if there is no match" do
      rewriter = Gemstash::GemSource::RackEnvRewriter.new(%r{\A/other})
      context = rewriter.for(env)
      expect(context.matches?).to be_falsey
      expect { context.rewrite }.to raise_error(RuntimeError)
      expect { context.params }.to raise_error(RuntimeError)
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
      rewriter = Gemstash::GemSource::RackEnvRewriter.new(%r{\A/upstream/([^/]+)})
      context = rewriter.for(env)
      expect(context.matches?).to be_truthy
      context.rewrite
      expect(context.params).to match_array([escaped_upstream_url])
      expect(env["REQUEST_URI"]).to eq("/some/path?arg=abc")
      expect(env["PATH_INFO"]).to eq("/some/path")
    end

    it "doesn't do anything if there is no match" do
      rewriter = Gemstash::GemSource::RackEnvRewriter.new(%r{\A/redirect/([^/]+)})
      context = rewriter.for(env)
      expect(context.matches?).to be_falsey
      expect { context.rewrite }.to raise_error(RuntimeError)
      expect { context.params }.to raise_error(RuntimeError)
      expect(env["REQUEST_URI"]).to eq("/upstream/#{escaped_upstream_url}/some/path?arg=abc")
      expect(env["PATH_INFO"]).to eq("/upstream/#{escaped_upstream_url}/some/path")
    end
  end
end

describe Gemstash::GemSource do
  let(:app) { double }
  let(:middleware) { Gemstash::GemSource::RackMiddleware.new(app) }

  context "using private gem source" do
    let(:env) do
      {
        "gemstash.env" => Gemstash::Env.current,
        "REQUEST_URI" => "/private/some/path?arg=abc",
        "PATH_INFO" => "/private/some/path"
      }
    end

    let(:result) { double }

    it "sets the source to PrivateSource and rewrites the path" do
      expect(app).to receive(:call).with(env).and_return(result)
      expect(middleware.call(env)).to eq(result)
      expect(env["gemstash.gem_source"]).to eq(Gemstash::GemSource::PrivateSource)
      expect(env["REQUEST_URI"]).to eq("/some/path?arg=abc")
      expect(env["PATH_INFO"]).to eq("/some/path")
      expect(the_log).to include("Rewriting '/private/some/path?arg=abc' to '/some/path?arg=abc'")
    end
  end

  context "using a custom upstream" do
    let(:env) do
      {
        "gemstash.env" => Gemstash::Env.current,
        "REQUEST_URI" => "/upstream/#{escaped_upstream_url}/some/path?arg=abc",
        "PATH_INFO" => "/upstream/#{escaped_upstream_url}/some/path"
      }
    end

    let(:upstream_url) { "https://some.gemsite.com" }
    let(:escaped_upstream_url) { CGI.escape(upstream_url) }
    let(:result) { double }

    it "sets the source to UpstreamSource and rewrites the path" do
      expect(app).to receive(:call).with(env).and_return(result)
      expect(middleware.call(env)).to eq(result)
      expect(env["gemstash.gem_source"]).to eq(Gemstash::GemSource::UpstreamSource)
      expect(env["gemstash.upstream"]).to eq(upstream_url)
      expect(env["REQUEST_URI"]).to eq("/some/path?arg=abc")
      expect(env["PATH_INFO"]).to eq("/some/path")
      expect(the_log).to include("Rewriting '/upstream/#{escaped_upstream_url}\
/some/path?arg=abc' to '/some/path?arg=abc'")
    end
  end

  context "using the default upstream" do
    let(:env) do
      {
        "gemstash.env" => Gemstash::Env.current,
        "REQUEST_URI" => "/some/path?arg=abc",
        "PATH_INFO" => "/some/path"
      }
    end

    let(:upstream_url) { "https://www.rubygems.org" }
    let(:result) { double }

    it "sets the source to RubygemsSource" do
      expect(app).to receive(:call).with(env).and_return(result)
      expect(middleware.call(env)).to eq(result)
      expect(env["gemstash.gem_source"]).to eq(Gemstash::GemSource::RubygemsSource)
      expect(env["gemstash.upstream"]).to eq(upstream_url)
      expect(env["REQUEST_URI"]).to eq("/some/path?arg=abc")
      expect(env["PATH_INFO"]).to eq("/some/path")
      expect(the_log).to_not include("Rewriting ")
    end
  end
end
