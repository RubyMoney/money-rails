require "spec_helper"

describe Gemstash::SpecsBuilder do
  context "with no private gems" do
    it "returns an empty result" do
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to eq([])
    end

    it "returns an empty latest result" do
      result = Gemstash::SpecsBuilder.latest
      expect(Marshal.load(gunzip(result))).to eq([])
    end

    it "returns an empty prerelease result" do
      result = Gemstash::SpecsBuilder.prerelease
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

    let(:expected_latest_specs) do
      [["example", Gem::Version.new("0.0.2"), "ruby"],
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

    it "marshals and gzips the latest versions" do
      result = Gemstash::SpecsBuilder.latest
      expect(Marshal.load(gunzip(result))).to match_array(expected_latest_specs)
    end

    it "returns an empty prerelease result" do
      result = Gemstash::SpecsBuilder.prerelease
      expect(Marshal.load(gunzip(result))).to eq([])
    end
  end

  context "with some prerelease gems" do
    let(:expected_prerelease_specs) do
      [["example", Gem::Version.new("0.0.2.rc1"), "ruby"],
       ["example", Gem::Version.new("0.0.2.rc2"), "ruby"],
       ["example", Gem::Version.new("0.0.2.rc2"), "java"],
       ["other-example", Gem::Version.new("0.1.1.rc1"), "ruby"]]
    end

    before do
      gem_id = insert_rubygem("example")
      insert_version(gem_id, "0.0.2.rc1", prerelease: true)
      insert_version(gem_id, "0.0.2.rc2", prerelease: true)
      insert_version(gem_id, "0.0.2.rc2", platform: "java", prerelease: true)
      gem_id = insert_rubygem("other-example")
      insert_version(gem_id, "0.1.1.rc1", prerelease: true)
    end

    it "returns an empty result" do
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to eq([])
    end

    it "returns an empty latest result" do
      result = Gemstash::SpecsBuilder.latest
      expect(Marshal.load(gunzip(result))).to eq([])
    end

    it "marshals and gzips the prerelease versions" do
      result = Gemstash::SpecsBuilder.prerelease
      expect(Marshal.load(gunzip(result))).to match_array(expected_prerelease_specs)
    end
  end

  context "with some private and prerelease gems" do
    let(:expected_specs) do
      [["example", Gem::Version.new("0.0.1"), "ruby"],
       ["example", Gem::Version.new("0.0.2"), "ruby"],
       ["example", Gem::Version.new("0.0.2"), "java"],
       ["other-example", Gem::Version.new("0.1.0"), "ruby"]]
    end

    let(:expected_latest_specs) do
      [["example", Gem::Version.new("0.0.2"), "ruby"],
       ["example", Gem::Version.new("0.0.2"), "java"],
       ["other-example", Gem::Version.new("0.1.0"), "ruby"]]
    end

    let(:expected_prerelease_specs) do
      [["example", Gem::Version.new("0.0.2.rc1"), "ruby"],
       ["example", Gem::Version.new("0.0.2.rc2"), "ruby"],
       ["example", Gem::Version.new("0.0.2.rc2"), "java"],
       ["other-example", Gem::Version.new("0.1.1.rc1"), "ruby"]]
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
      insert_version(gem_id, "0.1.1.rc1", prerelease: true)
    end

    it "marshals and gzips the versions" do
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to match_array(expected_specs)
    end

    it "marshals and gzips the latest versions" do
      result = Gemstash::SpecsBuilder.latest
      expect(Marshal.load(gunzip(result))).to match_array(expected_latest_specs)
    end

    it "marshals and gzips the prerelease versions" do
      result = Gemstash::SpecsBuilder.prerelease
      expect(Marshal.load(gunzip(result))).to match_array(expected_prerelease_specs)
    end
  end

  context "with some yanked gems" do
    let(:expected_specs) do
      [["example", Gem::Version.new("0.0.1"), "ruby"],
       ["example", Gem::Version.new("0.0.2"), "ruby"],
       ["example", Gem::Version.new("0.0.2"), "java"],
       ["other-example", Gem::Version.new("0.1.0"), "ruby"]]
    end

    let(:expected_latest_specs) do
      [["example", Gem::Version.new("0.0.2"), "ruby"],
       ["example", Gem::Version.new("0.0.2"), "java"],
       ["other-example", Gem::Version.new("0.1.0"), "ruby"]]
    end

    let(:expected_prerelease_specs) do
      [["example", Gem::Version.new("0.0.2.rc1"), "ruby"],
       ["example", Gem::Version.new("0.0.2.rc2"), "ruby"],
       ["example", Gem::Version.new("0.0.2.rc2"), "java"],
       ["other-example", Gem::Version.new("0.1.1.rc1"), "ruby"]]
    end

    before do
      gem_id = insert_rubygem("example")
      insert_version(gem_id, "0.0.1")
      insert_version(gem_id, "0.0.2.rc1", prerelease: true)
      insert_version(gem_id, "0.0.2.rc2", prerelease: true)
      insert_version(gem_id, "0.0.2.rc2", platform: "java", prerelease: true)
      insert_version(gem_id, "0.0.2")
      insert_version(gem_id, "0.0.2", platform: "java")
      insert_version(gem_id, "0.0.3.rc1", indexed: false, prerelease: true)
      insert_version(gem_id, "0.0.3", indexed: false)
      insert_version(gem_id, "0.0.3.rc1", indexed: false, prerelease: true, platform: "java")
      insert_version(gem_id, "0.0.3", indexed: false, platform: "java")
      gem_id = insert_rubygem("other-example")
      insert_version(gem_id, "0.0.1", indexed: false)
      insert_version(gem_id, "0.0.1.rc1", indexed: false, prerelease: true)
      insert_version(gem_id, "0.1.0")
      insert_version(gem_id, "0.1.1.rc1", prerelease: true)
    end

    it "marshals and gzips the versions" do
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to match_array(expected_specs)
    end

    it "marshals and gzips the latest versions" do
      result = Gemstash::SpecsBuilder.latest
      expect(Marshal.load(gunzip(result))).to match_array(expected_latest_specs)
    end

    it "marshals and gzips the prerelease versions" do
      result = Gemstash::SpecsBuilder.prerelease
      expect(Marshal.load(gunzip(result))).to match_array(expected_prerelease_specs)
    end
  end

  context "with a new spec pushed" do
    let(:initial_specs) { [["example", Gem::Version.new("0.0.1"), "ruby"]] }
    let(:new_specs) { [["example", Gem::Version.new("0.1.0"), "ruby"]] }
    let(:specs_after_push) { initial_specs + new_specs }

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

    it "busts the latest cache" do
      result = Gemstash::SpecsBuilder.latest
      expect(Marshal.load(gunzip(result))).to match_array(initial_specs)
      Gemstash::GemPusher.new("auth-key", read_gem("example", "0.1.0")).push
      result = Gemstash::SpecsBuilder.latest
      expect(Marshal.load(gunzip(result))).to match_array(new_specs)
    end
  end

  context "with a new prerelease spec pushed" do
    let(:initial_specs) { [["example", Gem::Version.new("0.0.1.pre"), "ruby"]] }
    let(:specs_after_push) { initial_specs + [["example", Gem::Version.new("0.1.0.pre"), "ruby"]] }

    before do
      Gemstash::Authorization.authorize("auth-key", "all")
      gem_id = insert_rubygem("example")
      insert_version(gem_id, "0.0.1.pre", prerelease: true)
    end

    it "busts the cache" do
      result = Gemstash::SpecsBuilder.prerelease
      expect(Marshal.load(gunzip(result))).to match_array(initial_specs)
      Gemstash::GemPusher.new("auth-key", read_gem("example", "0.1.0.pre")).push
      result = Gemstash::SpecsBuilder.prerelease
      expect(Marshal.load(gunzip(result))).to match_array(specs_after_push)
    end
  end

  context "with a spec yanked" do
    let(:initial_specs) do
      [["example", Gem::Version.new("0.0.1"), "ruby"],
       ["example", Gem::Version.new("0.1.0"), "ruby"]]
    end

    let(:latest_specs) { [["example", Gem::Version.new("0.1.0"), "ruby"]] }

    let(:specs_after_yank) { [["example", Gem::Version.new("0.0.1"), "ruby"]] }

    before do
      Gemstash::Authorization.authorize("auth-key", "all")
      gem_id = insert_rubygem("example")
      insert_version(gem_id, "0.0.1")
      Gemstash::GemPusher.new("auth-key", read_gem("example", "0.1.0")).push
    end

    it "busts the cache" do
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to match_array(initial_specs)
      Gemstash::GemYanker.new("auth-key", "example", "0.1.0").yank
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to match_array(specs_after_yank)
    end

    it "busts the latest cache" do
      result = Gemstash::SpecsBuilder.latest
      expect(Marshal.load(gunzip(result))).to match_array(latest_specs)
      Gemstash::GemYanker.new("auth-key", "example", "0.1.0").yank
      result = Gemstash::SpecsBuilder.latest
      expect(Marshal.load(gunzip(result))).to match_array(specs_after_yank)
    end
  end

  context "with a prerelease spec yanked" do
    let(:initial_specs) do
      [["example", Gem::Version.new("0.0.1.pre"), "ruby"],
       ["example", Gem::Version.new("0.1.0.pre"), "ruby"]]
    end

    let(:specs_after_yank) { [["example", Gem::Version.new("0.0.1.pre"), "ruby"]] }

    before do
      Gemstash::Authorization.authorize("auth-key", "all")
      gem_id = insert_rubygem("example")
      insert_version(gem_id, "0.0.1.pre", prerelease: true)
      Gemstash::GemPusher.new("auth-key", read_gem("example", "0.1.0.pre")).push
    end

    it "busts the cache" do
      result = Gemstash::SpecsBuilder.prerelease
      expect(Marshal.load(gunzip(result))).to match_array(initial_specs)
      Gemstash::GemYanker.new("auth-key", "example", "0.1.0.pre").yank
      result = Gemstash::SpecsBuilder.prerelease
      expect(Marshal.load(gunzip(result))).to match_array(specs_after_yank)
    end
  end

  context "with a spec unyanked" do
    let(:initial_specs) { [["example", Gem::Version.new("0.0.1"), "ruby"]] }
    let(:new_specs) { [["example", Gem::Version.new("0.1.0"), "ruby"]] }
    let(:specs_after_unyank) { initial_specs + new_specs }

    before do
      Gemstash::Authorization.authorize("auth-key", "all")
      gem_id = insert_rubygem("example")
      insert_version(gem_id, "0.0.1")
      Gemstash::GemPusher.new("auth-key", read_gem("example", "0.1.0")).push
      Gemstash::GemYanker.new("auth-key", "example", "0.1.0").yank
    end

    it "busts the cache" do
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to match_array(initial_specs)
      Gemstash::GemUnyanker.new("auth-key", "example", "0.1.0").unyank
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to match_array(specs_after_unyank)
    end

    it "busts the latest cache" do
      result = Gemstash::SpecsBuilder.latest
      expect(Marshal.load(gunzip(result))).to match_array(initial_specs)
      Gemstash::GemUnyanker.new("auth-key", "example", "0.1.0").unyank
      result = Gemstash::SpecsBuilder.latest
      expect(Marshal.load(gunzip(result))).to match_array(new_specs)
    end
  end

  context "with a prerelease spec unyanked" do
    let(:initial_specs) { [["example", Gem::Version.new("0.0.1.pre"), "ruby"]] }
    let(:specs_after_unyank) { initial_specs + [["example", Gem::Version.new("0.1.0.pre"), "ruby"]] }

    before do
      Gemstash::Authorization.authorize("auth-key", "all")
      gem_id = insert_rubygem("example")
      insert_version(gem_id, "0.0.1.pre", prerelease: true)
      Gemstash::GemPusher.new("auth-key", read_gem("example", "0.1.0.pre")).push
      Gemstash::GemYanker.new("auth-key", "example", "0.1.0.pre").yank
    end

    it "busts the cache" do
      result = Gemstash::SpecsBuilder.prerelease
      expect(Marshal.load(gunzip(result))).to match_array(initial_specs)
      Gemstash::GemUnyanker.new("auth-key", "example", "0.1.0.pre").unyank
      result = Gemstash::SpecsBuilder.prerelease
      expect(Marshal.load(gunzip(result))).to match_array(specs_after_unyank)
    end
  end
end
