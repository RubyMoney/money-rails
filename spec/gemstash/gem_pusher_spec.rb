require "spec_helper"

describe Gemstash::GemPusher do
  describe ".push" do
    context "with an unknown gem name" do
      let(:web_helper) { double }
      let(:deps) { Gemstash::Dependencies.new(web_helper) }
      let(:gem_contents) { File.read(file_path("example-0.1.0.gem")) }

      it "saves the dependency info" do
        Gemstash::GemPusher.new(gem_contents).push
        results = deps.fetch(%w(example)).first
        expect(results[:name]).to eq("example")
        expect(results[:number]).to eq("0.1.0")
        expect(results[:platform]).to eq("ruby")
        expect(results[:dependencies]).
          to match_array([["sqlite3", "~> 1.3"], ["thor", "~> 0.19"]])
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
