require "spec_helper"
require "zlib"

describe Gemstash::GemPusher do
  let(:auth) { Gemstash::ApiKeyAuthorization.new(auth_key) }
  let(:auth_with_invalid_auth_key) { Gemstash::ApiKeyAuthorization.new(invalid_auth_key) }
  let(:auth_without_permission) { Gemstash::ApiKeyAuthorization.new(auth_key_without_permission) }
  let(:auth_key) { "auth-key" }
  let(:invalid_auth_key) { "invalid-auth-key" }
  let(:auth_key_without_permission) { "auth-key-without-permission" }
  let(:storage) { Gemstash::Storage.for("private").for("gems") }

  before do
    Gemstash::Authorization.authorize(auth_key, "all")
    Gemstash::Authorization.authorize(auth_key_without_permission, ["yank"])
  end

  describe ".serve" do
    let(:deps) { Gemstash::Dependencies.for_private }
    let(:gem_contents) { read_gem("example", "0.1.0") }

    context "without authorization" do
      it "prevents pushing" do
        expect { Gemstash::GemPusher.new(Gemstash::ApiKeyAuthorization.new(nil), gem_contents).serve }.
          to raise_error(Gemstash::NotAuthorizedError)
        expect { Gemstash::GemPusher.new(Gemstash::ApiKeyAuthorization.new(""), gem_contents).serve }.
          to raise_error(Gemstash::NotAuthorizedError)
        expect(deps.fetch(%w(example))).to eq([])
      end
    end

    context "with invalid authorization" do
      it "prevents pushing" do
        expect { Gemstash::GemPusher.new(auth_with_invalid_auth_key, gem_contents).serve }.
          to raise_error(Gemstash::NotAuthorizedError)
        expect(deps.fetch(%w(example))).to eq([])
      end
    end

    context "with invalid permission" do
      it "prevents pushing" do
        expect { Gemstash::GemPusher.new(auth_without_permission, gem_contents).serve }.
          to raise_error(Gemstash::NotAuthorizedError)
        expect(deps.fetch(%w(example))).to eq([])
      end
    end

    context "with an unknown gem name" do
      it "saves the dependency info and stores the gem" do
        results = [{
          :name => "example",
          :number => "0.1.0",
          :platform => "ruby",
          :dependencies => [["sqlite3", "~> 1.3"],
                            ["thor", "~> 0.19"]]
        }]

        # Fetch before, asserting cache will be invalidated
        expect(deps.fetch(%w(example))).to eq([])
        Gemstash::GemPusher.new(auth, gem_contents).serve
        expect(deps.fetch(%w(example))).to match_dependencies(results)
        expect(storage.resource("example-0.1.0").content(:gem)).to eq(gem_contents)
      end

      it "stores the gemspec" do
        Gemstash::GemPusher.new(auth, gem_contents).serve
        spec = storage.resource("example-0.1.0").content(:spec)
        spec = Marshal.load(Zlib::Inflate.inflate(spec))
        expect(spec).to be_a(Gem::Specification)
        expect(spec.name).to eq("example")
        expect(spec.version.to_s).to eq("0.1.0")
        expect(spec.platform.to_s).to eq("ruby")
      end
    end

    context "with a non-ruby platform" do
      let(:gem_contents) { read_gem("example", "0.1.0-java") }

      it "saves the dependency info and stores the gem" do
        results = [{
          :name => "example",
          :number => "0.1.0",
          :platform => "java",
          :dependencies => [["sqlite3", "~> 1.3"],
                            ["thor", "~> 0.19"]]
        }]

        # Fetch before, asserting cache will be invalidated
        expect(deps.fetch(%w(example))).to eq([])
        Gemstash::GemPusher.new(auth, gem_contents).serve
        expect(deps.fetch(%w(example))).to match_dependencies(results)
        expect(storage.resource("example-0.1.0-java").content(:gem)).to eq(gem_contents)
      end

      it "stores the gemspec" do
        Gemstash::GemPusher.new(auth, gem_contents).serve
        spec = storage.resource("example-0.1.0-java").content(:spec)
        spec = Marshal.load(Zlib::Inflate.inflate(spec))
        expect(spec).to be_a(Gem::Specification)
        expect(spec.name).to eq("example")
        expect(spec.version.to_s).to eq("0.1.0")
        expect(spec.platform.to_s).to eq("java")
      end
    end

    context "with an exsiting gem name" do
      before do
        gem_id = insert_rubygem "example"
        insert_version gem_id, "0.0.1"
        storage.resource("example-0.0.1").save({ gem: "zapatito" }, indexed: true)
      end

      it "saves the new version dependency info and stores the gem" do
        results = [{
          :name => "example",
          :number => "0.0.1",
          :platform => "ruby",
          :dependencies => []
        }, {
          :name => "example",
          :number => "0.1.0",
          :platform => "ruby",
          :dependencies => [["sqlite3", "~> 1.3"],
                            ["thor", "~> 0.19"]]
        }]

        Gemstash::GemPusher.new(auth, gem_contents).serve
        expect(deps.fetch(%w(example))).to match_dependencies(results)
        expect(storage.resource("example-0.1.0").content(:gem)).to eq(gem_contents)
      end

      it "stores the gemspec" do
        Gemstash::GemPusher.new(auth, gem_contents).serve
        spec = storage.resource("example-0.1.0").content(:spec)
        spec = Marshal.load(Zlib::Inflate.inflate(spec))
        expect(spec).to be_a(Gem::Specification)
        expect(spec.name).to eq("example")
        expect(spec.version.to_s).to eq("0.1.0")
        expect(spec.platform.to_s).to eq("ruby")
      end
    end

    context "with a yanked version" do
      before do
        gem_id = insert_rubygem "example"
        insert_version gem_id, "0.1.0", indexed: false
        storage.resource("example-0.1.0").save({ gem: "zapatito" }, indexed: false)
      end

      it "rejects the push" do
        expect { Gemstash::GemPusher.new(auth, gem_contents).serve }.
          to raise_error(Gemstash::GemPusher::YankedVersionError)
      end
    end

    context "with an existing version" do
      before do
        gem_id = insert_rubygem "example"
        insert_version gem_id, "0.1.0"
        storage.resource("example-0.1.0").save({ gem: "zapatito" }, indexed: true)
      end

      it "rejects the push" do
        expect { Gemstash::GemPusher.new(auth, gem_contents).serve }.
          to raise_error(Gemstash::GemPusher::ExistingVersionError)
      end
    end
  end
end
