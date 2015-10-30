require "spec_helper"

describe Gemstash::SpecsBuilder do
  context "with no private gems" do
    it "returns an empty result" do
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to eq([])
    end
  end

  context "with some private gems" do
    let(:expected_specs) do
      [["example", Gem::Version.new("0.0.1"), "ruby"],
       ["example", Gem::Version.new("0.0.2"), "ruby"],
       ["example", Gem::Version.new("0.0.2"), "java"],
       ["other-example", Gem::Version.new("0.1.0"), "ruby"]]
    end

    before do
      gem_id = insert_rubygem("example")
      insert_version(gem_id, "0.0.1")
      insert_version(gem_id, "0.0.2")
      insert_version(gem_id, "0.0.2", platform: "java")
      gem_id = insert_rubygem("other-example")
      insert_version(gem_id, "0.1.0")
    end

    it "marshals and gzips the versions" do
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to match_array(expected_specs)
    end
  end

  context "with some prerelease gems" do
    let(:expected_specs) do
      [["example", Gem::Version.new("0.0.1"), "ruby"],
       ["example", Gem::Version.new("0.0.2"), "ruby"],
       ["example", Gem::Version.new("0.0.2"), "java"],
       ["other-example", Gem::Version.new("0.1.0"), "ruby"]]
    end

    before do
      gem_id = insert_rubygem("example")
      insert_version(gem_id, "0.0.1")
      insert_version(gem_id, "0.0.2.rc1", prerelease: true)
      insert_version(gem_id, "0.0.2.rc2", prerelease: true)
      insert_version(gem_id, "0.0.2.rc2", platform: "java", prerelease: true)
      insert_version(gem_id, "0.0.2")
      insert_version(gem_id, "0.0.2", platform: "java")
      gem_id = insert_rubygem("other-example")
      insert_version(gem_id, "0.1.0")
    end

    it "marshals and gzips the versions" do
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to match_array(expected_specs)
    end
  end

  context "with some yanked gems" do
    let(:expected_specs) do
      [["example", Gem::Version.new("0.0.1"), "ruby"],
       ["example", Gem::Version.new("0.0.2"), "ruby"],
       ["example", Gem::Version.new("0.0.2"), "java"],
       ["other-example", Gem::Version.new("0.1.0"), "ruby"]]
    end

    before do
      gem_id = insert_rubygem("example")
      insert_version(gem_id, "0.0.1")
      insert_version(gem_id, "0.0.2")
      insert_version(gem_id, "0.0.2", platform: "java")
      insert_version(gem_id, "0.0.3", indexed: false)
      insert_version(gem_id, "0.0.3", indexed: false, platform: "java")
      gem_id = insert_rubygem("other-example")
      insert_version(gem_id, "0.0.1", indexed: false)
      insert_version(gem_id, "0.1.0")
    end

    it "marshals and gzips the versions" do
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to match_array(expected_specs)
    end
  end

  context "with a new spec pushed" do
    let(:initial_specs) { [["example", Gem::Version.new("0.0.1"), "ruby"]] }
    let(:specs_after_push) { initial_specs + [["example", Gem::Version.new("0.1.0"), "ruby"]] }

    before do
      Gemstash::Authorization.authorize("auth-key", "all")
      gem_id = insert_rubygem("example")
      insert_version(gem_id, "0.0.1")
    end

    it "busts the cache" do
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to match_array(initial_specs)
      Gemstash::GemPusher.new("auth-key", read_gem("example", "0.1.0")).push
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to match_array(specs_after_push)
    end
  end
end
