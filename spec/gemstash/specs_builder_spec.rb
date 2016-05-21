require "spec_helper"

describe Gemstash::SpecsBuilder do
  let(:auth) { Gemstash::ApiKeyAuthorization.new(auth_key) }
  let(:auth_key) { "auth-key" }

  context "with no private gems" do
    it "returns an empty result" do
      result = Gemstash::SpecsBuilder.all
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

    it "marshals and gzips the prerelease versions" do
      result = Gemstash::SpecsBuilder.prerelease
      expect(Marshal.load(gunzip(result))).to match_array(expected_prerelease_specs)
    end
  end

  context "with a new spec pushed" do
    let(:initial_specs) { [["example", Gem::Version.new("0.0.1"), "ruby"]] }
    let(:specs_after_push) { initial_specs + [["example", Gem::Version.new("0.1.0"), "ruby"]] }

    before do
      Gemstash::Authorization.authorize(auth_key, "all")
      gem_id = insert_rubygem("example")
      insert_version(gem_id, "0.0.1")
    end

    it "busts the cache" do
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to match_array(initial_specs)
      Gemstash::GemPusher.new(auth, read_gem("example", "0.1.0")).serve
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to match_array(specs_after_push)
    end
  end

  context "with a new prerelease spec pushed" do
    let(:initial_specs) { [["example", Gem::Version.new("0.0.1.pre"), "ruby"]] }
    let(:specs_after_push) { initial_specs + [["example", Gem::Version.new("0.1.0.pre"), "ruby"]] }

    before do
      Gemstash::Authorization.authorize(auth_key, "all")
      gem_id = insert_rubygem("example")
      insert_version(gem_id, "0.0.1.pre", prerelease: true)
    end

    it "busts the cache" do
      result = Gemstash::SpecsBuilder.prerelease
      expect(Marshal.load(gunzip(result))).to match_array(initial_specs)
      Gemstash::GemPusher.new(auth, read_gem("example", "0.1.0.pre")).serve
      result = Gemstash::SpecsBuilder.prerelease
      expect(Marshal.load(gunzip(result))).to match_array(specs_after_push)
    end
  end

  context "with a spec yanked" do
    let(:initial_specs) do
      [["example", Gem::Version.new("0.0.1"), "ruby"],
       ["example", Gem::Version.new("0.1.0"), "ruby"]]
    end

    let(:specs_after_yank) { [["example", Gem::Version.new("0.0.1"), "ruby"]] }

    before do
      Gemstash::Authorization.authorize(auth_key, "all")
      gem_id = insert_rubygem("example")
      insert_version(gem_id, "0.0.1")
      Gemstash::GemPusher.new(auth, read_gem("example", "0.1.0")).serve
    end

    it "busts the cache" do
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to match_array(initial_specs)
      Gemstash::GemYanker.new(auth, "example", "0.1.0").serve
      result = Gemstash::SpecsBuilder.all
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
      Gemstash::Authorization.authorize(auth_key, "all")
      gem_id = insert_rubygem("example")
      insert_version(gem_id, "0.0.1.pre", prerelease: true)
      Gemstash::GemPusher.new(auth, read_gem("example", "0.1.0.pre")).serve
    end

    it "busts the cache" do
      result = Gemstash::SpecsBuilder.prerelease
      expect(Marshal.load(gunzip(result))).to match_array(initial_specs)
      Gemstash::GemYanker.new(auth, "example", "0.1.0.pre").serve
      result = Gemstash::SpecsBuilder.prerelease
      expect(Marshal.load(gunzip(result))).to match_array(specs_after_yank)
    end
  end

  context "with a spec unyanked" do
    let(:initial_specs) { [["example", Gem::Version.new("0.0.1"), "ruby"]] }
    let(:specs_after_unyank) { initial_specs + [["example", Gem::Version.new("0.1.0"), "ruby"]] }

    before do
      Gemstash::Authorization.authorize(auth_key, "all")
      gem_id = insert_rubygem("example")
      insert_version(gem_id, "0.0.1")
      Gemstash::GemPusher.new(auth, read_gem("example", "0.1.0")).serve
      Gemstash::GemYanker.new(auth, "example", "0.1.0").serve
    end

    it "busts the cache" do
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to match_array(initial_specs)
      Gemstash::GemUnyanker.new(auth, "example", "0.1.0").serve
      result = Gemstash::SpecsBuilder.all
      expect(Marshal.load(gunzip(result))).to match_array(specs_after_unyank)
    end
  end

  context "with a prerelease spec unyanked" do
    let(:initial_specs) { [["example", Gem::Version.new("0.0.1.pre"), "ruby"]] }
    let(:specs_after_unyank) { initial_specs + [["example", Gem::Version.new("0.1.0.pre"), "ruby"]] }

    before do
      Gemstash::Authorization.authorize(auth_key, "all")
      gem_id = insert_rubygem("example")
      insert_version(gem_id, "0.0.1.pre", prerelease: true)
      Gemstash::GemPusher.new(auth, read_gem("example", "0.1.0.pre")).serve
      Gemstash::GemYanker.new(auth, "example", "0.1.0.pre").serve
    end

    it "busts the cache" do
      result = Gemstash::SpecsBuilder.prerelease
      expect(Marshal.load(gunzip(result))).to match_array(initial_specs)
      Gemstash::GemUnyanker.new(auth, "example", "0.1.0.pre").serve
      result = Gemstash::SpecsBuilder.prerelease
      expect(Marshal.load(gunzip(result))).to match_array(specs_after_unyank)
    end
  end
end
