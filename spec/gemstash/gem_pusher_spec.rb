require "spec_helper"

describe Gemstash::GemPusher do
  let(:auth_key) { "auth-key" }
  let(:invalid_auth_key) { "invalid-auth-key" }
  let(:auth_key_without_permission) { "auth-key-without-permission" }

  before do
    Gemstash::Authorization.authorize(auth_key, "all")
    Gemstash::Authorization.authorize(auth_key_without_permission, invalid_permission)
  end

  describe ".push" do
    let(:invalid_permission) { "yank" }
    let(:web_helper) { double }
    let(:deps) { Gemstash::Dependencies.new(web_helper) }
    let(:gem_contents) { File.read(gem_path("example", "0.1.0")) }

    context "without authorization" do
      it "prevents pushing" do
        allow(web_helper).to receive(:get).and_return(Marshal.dump([]))
        expect { Gemstash::GemPusher.new(nil, gem_contents).push }.to raise_error(Gemstash::NotAuthorizedError)
        expect { Gemstash::GemPusher.new("", gem_contents).push }.to raise_error(Gemstash::NotAuthorizedError)
        expect(deps.fetch(%w(example))).to eq([])
      end
    end

    context "with invalid authorization" do
      it "prevents pushing" do
        allow(web_helper).to receive(:get).and_return(Marshal.dump([]))
        expect { Gemstash::GemPusher.new(invalid_auth_key, gem_contents).push }.
          to raise_error(Gemstash::NotAuthorizedError)
        expect(deps.fetch(%w(example))).to eq([])
      end
    end

    context "with invalid permission" do
      it "prevents pushing" do
        allow(web_helper).to receive(:get).and_return(Marshal.dump([]))
        expect { Gemstash::GemPusher.new(auth_key_without_permission, gem_contents).push }.
          to raise_error(Gemstash::NotAuthorizedError)
        expect(deps.fetch(%w(example))).to eq([])
      end
    end

    context "with an unknown gem name" do
      it "saves the dependency info" do
        allow(web_helper).to receive(:get).and_return(Marshal.dump([]))

        results = [{
          :name => "example",
          :number => "0.1.0",
          :platform => "ruby",
          :dependencies => [["sqlite3", "~> 1.3"],
                            ["thor", "~> 0.19"]]
        }]

        # Fetch before, asserting cache will be invalidated
        expect(deps.fetch(%w(example))).to eq([])
        Gemstash::GemPusher.new(auth_key, gem_contents).push
        expect(deps.fetch(%w(example))).to match_dependencies(results)
      end
    end

    context "with an exsiting gem name" do
      before do
        gem_id = insert_rubygem "example"
        insert_version gem_id, "0.0.1"
      end

      it "saves the new version dependency info" do
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

        Gemstash::GemPusher.new(auth_key, gem_contents).push
        expect(deps.fetch(%w(example))).to match_dependencies(results)
      end
    end

    context "with a yanked version" do
      before do
        gem_id = insert_rubygem "example"
        insert_version gem_id, "0.1.0", "ruby", false
      end

      it "rejects the push" do
        expect { Gemstash::GemPusher.new(auth_key, gem_contents).push }.
          to raise_error(Gemstash::GemPusher::YankedVersionError)
      end
    end

    context "with an existing version" do
      before do
        gem_id = insert_rubygem "example"
        insert_version gem_id, "0.1.0"
      end

      it "rejects the push" do
        expect { Gemstash::GemPusher.new(auth_key, gem_contents).push }.
          to raise_error(Gemstash::GemPusher::ExistingVersionError)
      end
    end
  end
end
