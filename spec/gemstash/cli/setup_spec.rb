require "spec_helper"
require "yaml"

describe Gemstash::CLI::Setup do
  let(:cli) do
    result = double(options: cli_options, say: nil)
    allow(result).to receive(:set_color) {|x| x }
    result
  end

  let(:cli_options) do
    {
      redo: false,
      config_file: File.join(TEST_BASE_PATH, "setup_spec_config.yml")
    }
  end

  before do
    @test_env = test_env
    Gemstash::Env.current = Gemstash::Env.new(TEST_CONFIG)
    defaults = Gemstash::Configuration::DEFAULTS.merge(base_path: TEST_BASE_PATH)
    stub_const("Gemstash::Configuration::DEFAULTS", defaults)
  end

  after do
    Gemstash::Env.current = @test_env
  end

  context "accepting all defaults" do
    it "saves the config with defaults" do
      allow(cli).to receive(:ask).and_return("")
      expect(File.exist?(cli_options[:config_file])).to be_falsey
      # This is expected to touch the metadata file, which we don't want to
      # write out (it would go in ~/.gemstash rather than our test path)
      expect(Gemstash::Storage).to receive(:metadata)
      Gemstash::CLI::Setup.new(cli).run
      expect(File.exist?(cli_options[:config_file])).to be_truthy
      config = YAML.load_file(cli_options[:config_file])

      config.each do |key, value|
        expect(value).to eq(Gemstash::Configuration::DEFAULTS[key])
      end
    end
  end

  context "with a storage that already indicates a newer version of gemstash" do
    let(:metadata) { { storage_version: Gemstash::Storage::VERSION, gemstash_version: "999999.0.0" } }
    let(:metadata_path) { File.join(TEST_BASE_PATH, "metadata.yml") }

    it "errors immediately" do
      File.write metadata_path, metadata.to_yaml
      allow(cli).to receive(:ask).and_return("")
      expect(cli).to receive(:ask).with("Where should files go? [~/.gemstash]", path: true).and_return(TEST_BASE_PATH)
      expect(File.exist?(cli_options[:config_file])).to be_falsey
      expect { Gemstash::CLI::Setup.new(cli).run }.to raise_error(Gemstash::CLI::Error, /newer version/)
      expect(File.exist?(cli_options[:config_file])).to be_falsey
    end
  end

  context "with invalid cache setup" do
    let(:cache_client) { double }

    it "errors when cehcking the cache" do
      allow(cli).to receive(:ask).and_return("")
      expect(cli).to receive(:ask).with("Where should files go? [~/.gemstash]", path: true).and_return(TEST_BASE_PATH)
      allow_any_instance_of(Gemstash::Env).to receive(:cache_client).and_return(cache_client)
      expect(cache_client).to receive(:alive!).and_raise("Invalid cache setup!")
      expect(File.exist?(cli_options[:config_file])).to be_falsey
      expect { Gemstash::CLI::Setup.new(cli).run }.to raise_error(Gemstash::CLI::Error, /The cache is not available/)
      expect(File.exist?(cli_options[:config_file])).to be_falsey
    end
  end

  context "with invalid database setup" do
    let(:database) { double }

    it "errors when cehcking the cache" do
      allow(cli).to receive(:ask).and_return("")
      expect(cli).to receive(:ask).with("Where should files go? [~/.gemstash]", path: true).and_return(TEST_BASE_PATH)
      allow_any_instance_of(Gemstash::Env).to receive(:db).and_return(database)
      expect(database).to receive(:test_connection).and_raise("Invalid db setup!")
      expect(File.exist?(cli_options[:config_file])).to be_falsey
      expect { Gemstash::CLI::Setup.new(cli).run }.to raise_error(Gemstash::CLI::Error, /The database is not available/)
      expect(File.exist?(cli_options[:config_file])).to be_falsey
    end
  end
end
