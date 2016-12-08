require "spec_helper"

describe Gemstash::Configuration do
  let(:config_dir) { config_path("configuration_spec") }

  context "no config file" do
    let(:env) { Gemstash::Env.new }

    it "loads the default config" do
      expect(env.config[:db_adapter]).to eq("sqlite3")
      expect(env.config.database_connection_config).to match(hash_including(max_connections: 1))
    end
  end

  context "erb config file" do
    before do
      ENV["DATABASE_URL"] = "postgres://rendered-erb"
    end
    let(:config) { Gemstash::Configuration.new(file: "#{config_dir}/config.yml.erb") }
    let(:env) { Gemstash::Env.new(config) }

    it "interprets the erb, loads yaml and merges with defaults" do
      expect(env.config[:db_adapter]).to eq("postgres")
      expect(env.config[:db_url]).to eq("postgres://rendered-erb")
      expect(env.config.database_connection_config).to match(hash_including(max_connections: 17))
    end
  end

  context "plain yaml config file" do
    let(:config) { Gemstash::Configuration.new(file: "#{config_dir}/config.yml") }
    let(:env) { Gemstash::Env.new(config) }

    it "merges the yaml config with defaults" do
      expect(env.config[:db_adapter]).to eq("postgres")
      expect(env.config[:db_url]).to eq("postgres://gemstash")
    end
  end

  context "empty yaml config file" do
    let(:config) { Gemstash::Configuration.new(file: "#{config_dir}/empty-config.yml") }
    let(:env) { Gemstash::Env.new(config) }

    it "loads the default config" do
      expect(env.config[:db_adapter]).to eq("sqlite3")
    end
  end
end
