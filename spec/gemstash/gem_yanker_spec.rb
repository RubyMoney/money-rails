require "spec_helper"

describe Gemstash::GemYanker do
  let(:auth_key) { "auth-key" }
  let(:invalid_auth_key) { "invalid-auth-key" }
  let(:auth_key_without_permission) { "auth-key-without-permission" }
  let(:storage) { Gemstash::Storage.for("private").for("gems") }
  let(:deps) { Gemstash::Dependencies.for_private }
  let(:gem_name) { "example" }
  let(:gem_version) { "0.1.0" }

  let(:gem_dependencies) do
    {
      :name => "example",
      :number => "0.1.0",
      :platform => "ruby",
      :dependencies => [["sqlite3", "~> 1.3"],
                        ["thor", "~> 0.19"]]
    }
  end

  before do
    Gemstash::Authorization.authorize(auth_key, "all")
    Gemstash::Authorization.authorize(auth_key_without_permission, ["push"])
    Gemstash::GemPusher.new(auth_key, read_gem(gem_name, gem_version)).push
  end

  describe ".yank" do
    context "without authorization" do
      it "prevents yanking" do
        expect { Gemstash::GemYanker.new(nil, gem_name, gem_version).yank }.to raise_error(Gemstash::NotAuthorizedError)
        expect { Gemstash::GemYanker.new("", gem_name, gem_version).yank }.to raise_error(Gemstash::NotAuthorizedError)
        expect(deps.fetch(%w(example))).to eq([gem_dependencies])
      end
    end

    context "with invalid authorization" do
      it "prevents yanking" do
        expect { Gemstash::GemYanker.new(invalid_auth_key, gem_name, gem_version).yank }.
          to raise_error(Gemstash::NotAuthorizedError)
        expect(deps.fetch(%w(example))).to eq([gem_dependencies])
      end
    end

    context "with invalid permission" do
      it "prevents yanking" do
        expect { Gemstash::GemYanker.new(auth_key_without_permission, gem_name, gem_version).yank }.
          to raise_error(Gemstash::NotAuthorizedError)
        expect(deps.fetch(%w(example))).to eq([gem_dependencies])
      end
    end
  end
end
