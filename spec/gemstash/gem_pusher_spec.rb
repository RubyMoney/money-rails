require "spec_helper"

describe Gemstash::GemPusher do
  describe ".push" do
    let(:web_helper) { double }
    let(:deps) { Gemstash::Dependencies.new(web_helper) }
    let(:gem_contents) { File.read(file_path("example-0.1.0.gem")) }

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
      it "saves the new version dependency info"
    end

    context "with a yanked version" do
      it "rejects the push"
    end
  end
end
