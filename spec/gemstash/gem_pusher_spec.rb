require "spec_helper"

describe Gemstash::GemPusher do
  describe ".push" do
    let(:web_helper) { double }
    let(:deps) { Gemstash::Dependencies.new(web_helper) }
    let(:gem_contents) { File.read(gem_path("example", "0.1.0")) }

    context "with an unknown gem name" do
      it "saves the dependency info" do
        results = [{
          :name => "example",
          :number => "0.1.0",
          :platform => "ruby",
          :dependencies => [["sqlite3", "~> 1.3"],
                            ["thor", "~> 0.19"]]
        }]

        Gemstash::GemPusher.new(gem_contents).push
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

        Gemstash::GemPusher.new(gem_contents).push
        expect(deps.fetch(%w(example))).to match_dependencies(results)
      end
    end

    context "with a yanked version" do
      before do
        gem_id = insert_rubygem "example"
        insert_version gem_id, "0.1.0", "ruby", false
      end

      it "rejects the push" do
        expect { Gemstash::GemPusher.new(gem_contents).push }.
          to raise_error(Gemstash::GemPusher::YankedVersionError)
      end
    end

    context "with an existing version" do
      before do
        gem_id = insert_rubygem "example"
        insert_version gem_id, "0.1.0"
      end

      it "rejects the push" do
        expect { Gemstash::GemPusher.new(gem_contents).push }.
          to raise_error(Gemstash::GemPusher::ExistingVersionError)
      end
    end
  end
end
