require "spec_helper"

describe Gemstash::GemUnyanker do
  let(:auth_key) { "auth-key" }
  let(:invalid_auth_key) { "invalid-auth-key" }
  let(:auth_key_without_permission) { "auth-key-without-permission" }
  let(:storage) { Gemstash::Storage.for("private").for("gems") }
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
    Gemstash::GemYanker.new(auth_key, gem_name, gem_version).yank
  end

  describe ".unyank" do
    context "without authorization" do
      it "prevents unyanking" do
        expect { Gemstash::GemUnyanker.new(nil, gem_name, gem_slug).unyank }.to raise_error(Gemstash::NotAuthorizedError)
        expect { Gemstash::GemUnyanker.new("", gem_name, gem_slug).unyank }.to raise_error(Gemstash::NotAuthorizedError)
        expect(deps.fetch(%w(example))).to eq([])
      end
    end

    context "with invalid authorization" do
      it "prevents unyanking" do
        expect { Gemstash::GemUnyanker.new(invalid_auth_key, gem_name, gem_slug).unyank }.
          to raise_error(Gemstash::NotAuthorizedError)
        expect(deps.fetch(%w(example))).to eq([])
      end
    end

    context "with invalid permission" do
      it "prevents unyanking" do
        expect { Gemstash::GemUnyanker.new(auth_key_without_permission, gem_name, gem_slug).unyank }.
          to raise_error(Gemstash::NotAuthorizedError)
        expect(deps.fetch(%w(example))).to eq([])
      end
    end

    context "with an unknown gem name" do
      it "rejects the unyank" do
        expect { Gemstash::GemUnyanker.new(auth_key, "unknown", "0.4.2-ruby").unyank }.
          to raise_error(Gemstash::GemUnyanker::UnknownGemError)
      end
    end

    context "with an unknown gem version" do
      it "rejects the unyank" do
        expect { Gemstash::GemUnyanker.new(auth_key, gem_name, "0.4.2-ruby").unyank }.
          to raise_error(Gemstash::GemUnyanker::UnknownVersionError)
        expect(deps.fetch(%w(example))).to eq([])
      end
    end

    context "with a non-yanked gem version" do
      let(:alternate_deps) do
        {
          :name => "example",
          :number => "0.4.2",
          :platform => "ruby",
          :dependencies => []
        }
      end

      before do
        gem_id = find_rubygem_id(gem_name)
        insert_version gem_id, "0.4.2"
        storage.resource("#{gem_name}-0.4.2").save({ gem: "zapatito" }, indexed: true)
      end

      it "rejects the unyank" do
        expect { Gemstash::GemUnyanker.new(auth_key, gem_name, "0.4.2-ruby").unyank }.
          to raise_error(Gemstash::GemUnyanker::NotYankedVersionError)
        expect(deps.fetch(%w(example))).to match_dependencies([alternate_deps])
      end
    end

    context "with a yanked gem version" do
      let(:gem_contents) { read_gem(gem_name, gem_version) }

      it "unyanks the gem" do
        # Fetch before, asserting cache will be invalidated
        expect(deps.fetch(%w(example))).to eq([])
        Gemstash::GemUnyanker.new(auth_key, gem_name, gem_slug).unyank
        expect(deps.fetch(%w(example))).to eq([gem_dependencies])
        expect(storage.resource("#{gem_name}-#{gem_version}").content(:gem)).to eq(gem_contents)
      end
    end

    context "with an implicit platform" do
      it "unyanks the gem" do
        expect(deps.fetch(%w(example))).to eq([])
        Gemstash::GemUnyanker.new(auth_key, gem_name, gem_version).unyank
        expect(deps.fetch(%w(example))).to eq([gem_dependencies])
      end
    end

    context "with multiple yanked versions" do
      before do
        gem_id = find_rubygem_id(gem_name)
        insert_version gem_id, "0.0.1", indexed: false
        storage.resource("#{gem_name}-0.1.0").save({ gem: "zapatito" }, indexed: false)
      end

      it "unyanks just the specified gem version" do
        Gemstash::GemUnyanker.new(auth_key, gem_name, gem_slug).unyank
        expect(deps.fetch(%w(example))).to eq([gem_dependencies])
      end
    end

    context "with a yanked version with other platforms" do
      before do
        gem_id = find_rubygem_id(gem_name)
        insert_version gem_id, "0.1.0", platform: "java", indexed: false
        storage.resource("#{gem_name}-0.1.0-java").save({ gem: "zapatito" }, indexed: false)
      end

      it "unyanks just the specified gem version" do
        Gemstash::GemUnyanker.new(auth_key, gem_name, gem_slug).unyank
        expect(deps.fetch(%w(example))).to eq([gem_dependencies])
      end
    end

    context "with a yanked version and explicit platform with other platforms" do
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
        insert_version gem_id, "0.1.0", platform: "java", indexed: false
        storage.resource("#{gem_name}-0.1.0-java").save({ gem: "zapatito" }, indexed: false)
      end

      it "unyanks just the specified gem version" do
        Gemstash::GemUnyanker.new(auth_key, gem_name, "0.1.0-java").unyank
        expect(deps.fetch(%w(example))).to eq([alternate_deps])
      end
    end
  end
end
