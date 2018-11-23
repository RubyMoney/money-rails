# frozen_string_literal: true

require "spec_helper"

describe Gemstash::CLI::Base do
  let(:cli) do
    result = double(say: nil)
    allow(result).to receive(:set_color) {|x| x }
    result
  end

  before do
    # Don't actually allow the env to be updated
    allow(Gemstash::Env).to receive(:current=)
  end

  describe "#check_gemstash_version" do
    let(:base) { Gemstash::CLI::Base.new(cli) }

    it "allows loading when stored metadata is the same version" do
      allow(Gemstash::Storage).to receive(:metadata).and_return(gemstash_version: "1.0.0")
      stub_const("Gemstash::VERSION", "1.0.0")
      base.send(:check_gemstash_version)
    end

    it "allows loading when stored metadata is prerelease of the same version" do
      allow(Gemstash::Storage).to receive(:metadata).and_return(gemstash_version: "1.0.0.pre.1")
      stub_const("Gemstash::VERSION", "1.0.0")
      base.send(:check_gemstash_version)
    end

    it "blocks loading when this version is a prerelease of the stored metadata version" do
      allow(Gemstash::Storage).to receive(:metadata).and_return(gemstash_version: "1.0.0")
      stub_const("Gemstash::VERSION", "1.0.0.pre.1")
      expect { base.send(:check_gemstash_version) }.to raise_error(Gemstash::CLI::Error, /does not support version/)
    end

    it "allows loading when stored metadata is older" do
      allow(Gemstash::Storage).to receive(:metadata).and_return(gemstash_version: "0.1.0")
      stub_const("Gemstash::VERSION", "1.0.0")
      base.send(:check_gemstash_version)
    end

    it "allows loading when stored metadata is prerelease of an older version" do
      allow(Gemstash::Storage).to receive(:metadata).and_return(gemstash_version: "0.1.0.pre.1")
      stub_const("Gemstash::VERSION", "1.0.0")
      base.send(:check_gemstash_version)
    end

    it "blocks loading when stored metadata is newer" do
      allow(Gemstash::Storage).to receive(:metadata).and_return(gemstash_version: "1.1.0")
      stub_const("Gemstash::VERSION", "1.0.0")
      expect { base.send(:check_gemstash_version) }.to raise_error(Gemstash::CLI::Error, /does not support version/)
    end

    it "blocks loading when stored metadata is prerelease of a newer version" do
      allow(Gemstash::Storage).to receive(:metadata).and_return(gemstash_version: "1.1.0.pre.1")
      stub_const("Gemstash::VERSION", "1.0.0")
      expect { base.send(:check_gemstash_version) }.to raise_error(Gemstash::CLI::Error, /does not support version/)
    end
  end

  describe "#store_config" do
    let(:base) { Gemstash::CLI::Base.new(cli) }

    it "fails if the config file doesn't exist" do
      allow(cli).to receive(:options).and_return(config_file: File.join(TEST_BASE_PATH, "missing_file.yml"))
      expect { base.send(:store_config) }.to raise_error(Gemstash::CLI::Error, /missing_file\.yml/)
    end

    it "fails if the config file is specified as empty" do
      allow(cli).to receive(:options).and_return(config_file: "")
      expect { base.send(:store_config) }.to raise_error(Gemstash::CLI::Error, /Missing config file/)
    end
  end
end
