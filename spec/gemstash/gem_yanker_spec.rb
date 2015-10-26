require "spec_helper"

describe Gemstash::GemYanker do
  let(:auth_key) { "auth-key" }
  let(:invalid_auth_key) { "invalid-auth-key" }
  let(:auth_key_without_permission) { "auth-key-without-permission" }
  let(:deps) { Gemstash::Dependencies.for_private }
  let(:gem_name) { "example" }
  let(:gem_version) { "0.1.0" }
  let(:gem_slug) { "#{gem_version}-ruby" }

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
        expect { Gemstash::GemYanker.new(nil, gem_name, gem_slug).yank }.to raise_error(Gemstash::NotAuthorizedError)
        expect { Gemstash::GemYanker.new("", gem_name, gem_slug).yank }.to raise_error(Gemstash::NotAuthorizedError)
        expect(deps.fetch(%w(example))).to eq([gem_dependencies])
      end
    end

    context "with invalid authorization" do
      it "prevents yanking" do
        expect { Gemstash::GemYanker.new(invalid_auth_key, gem_name, gem_slug).yank }.
          to raise_error(Gemstash::NotAuthorizedError)
        expect(deps.fetch(%w(example))).to eq([gem_dependencies])
      end
    end

    context "with invalid permission" do
      it "prevents yanking" do
        expect { Gemstash::GemYanker.new(auth_key_without_permission, gem_name, gem_slug).yank }.
          to raise_error(Gemstash::NotAuthorizedError)
        expect(deps.fetch(%w(example))).to eq([gem_dependencies])
      end
    end

    context "with an unknown gem name" do
      it "rejects the yank" do
        expect { Gemstash::GemYanker.new(auth_key, "unknown", "0.4.2-ruby").yank }.
          to raise_error(Gemstash::GemYanker::UnknownGemError)
      end
    end

    context "with an unknown gem version" do
      it "rejects the yank" do
        expect { Gemstash::GemYanker.new(auth_key, gem_name, "0.4.2-ruby").yank }.
          to raise_error(Gemstash::GemYanker::UnknownVersionError)
        expect(deps.fetch(%w(example))).to eq([gem_dependencies])
      end
    end

    context "with a yanked gem version" do
      before do
        gem_id = find_rubygem_id(gem_name)
        insert_version gem_id, "0.4.2", "ruby", false
      end

      it "rejects the yank" do
        expect { Gemstash::GemYanker.new(auth_key, gem_name, "0.4.2-ruby").yank }.
          to raise_error(Gemstash::GemYanker::YankedVersionError)
        expect(deps.fetch(%w(example))).to eq([gem_dependencies])
      end
    end

    context "with an existing gem version" do
      let(:storage) { Gemstash::Storage.for("private").for("gems") }
      let(:gem_contents) { read_gem(gem_name, gem_version) }

      it "yanks the gem" do
        # Fetch before, asserting cache will be invalidated
        expect(deps.fetch(%w(example))).to eq([gem_dependencies])
        Gemstash::GemYanker.new(auth_key, gem_name, gem_slug).yank
        expect(deps.fetch(%w(example))).to eq([])
        # It doesn't actually delete
        expect(storage.resource("#{gem_name}-#{gem_version}").load.content).to eq(gem_contents)
      end
    end

    context "with an implicit platform" do
      it "yanks the gem" do
        expect(deps.fetch(%w(example))).to eq([gem_dependencies])
        Gemstash::GemYanker.new(auth_key, gem_name, gem_version).yank
        expect(deps.fetch(%w(example))).to eq([])
      end
    end

    context "with an existing gem version with other versions" do
      let(:alternate_deps) do
        {
          :name => "example",
          :number => "0.0.1",
          :platform => "ruby",
          :dependencies => []
        }
      end

      before do
        gem_id = find_rubygem_id(gem_name)
        insert_version gem_id, "0.0.1"
      end

      it "yanks just the specified gem version" do
        Gemstash::GemYanker.new(auth_key, gem_name, gem_slug).yank
        expect(deps.fetch(%w(example))).to eq([alternate_deps])
      end
    end

    context "with an existing gem version with other platforms" do
      let(:alternate_deps) do
        {
          :name => "example",
          :number => "0.1.0",
          :platform => "java",
          :dependencies => []
        }
      end

      before do
        gem_id = find_rubygem_id(gem_name)
        insert_version gem_id, "0.1.0", "java"
      end

      it "yanks just the specified gem version" do
        Gemstash::GemYanker.new(auth_key, gem_name, gem_slug).yank
        expect(deps.fetch(%w(example))).to eq([alternate_deps])
      end
    end

    context "with an existing gem version and explicit platform with other platforms" do
      before do
        gem_id = find_rubygem_id(gem_name)
        insert_version gem_id, "0.1.0", "java"
      end

      it "yanks just the specified gem version" do
        Gemstash::GemYanker.new(auth_key, gem_name, "0.1.0-java").yank
        expect(deps.fetch(%w(example))).to eq([gem_dependencies])
      end
    end
  end
end
