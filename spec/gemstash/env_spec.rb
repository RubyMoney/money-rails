# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gemstash::Env do
  context ".log_file" do
    let(:dir) { __dir__ }

    it "has a default log file path" do
      config = Gemstash::Configuration.new(config: { base_path: dir })
      env = Gemstash::Env.new(config)
      expect(env.log_file).to eq(File.join(dir, "server.log"))
    end

    it "supports a customized log file path" do
      config = Gemstash::Configuration.new(config: { base_path: dir, log_file: "my_log.log" })
      env = Gemstash::Env.new(config)
      expect(env.log_file).to eq(File.join(dir, "my_log.log"))
    end

    it "supports :stdout from config to obtain standard out" do
      config = Gemstash::Configuration.new(config: { log_file: :stdout })
      env = Gemstash::Env.new(config)
      expect(env.log_file).to eq($stdout)
    end
  end

  context ".pidfile" do
    let(:dir) { __dir__ }

    it "has default pidfile path" do
      config = Gemstash::Configuration.new(config: { base_path: dir })
      env = Gemstash::Env.new(config)
      expect(env.pidfile).to eq(File.join(dir, "puma.pid"))
    end

    it "supports relative path" do
      config = Gemstash::Configuration.new(config: { base_path: dir, pidfile: "custom/puma.pid" })
      env = Gemstash::Env.new(config)
      expect(env.pidfile).to eq(File.join(dir, "custom", "puma.pid"))
    end

    it "supports absolute path" do
      config = Gemstash::Configuration.new(config: { base_path: dir, pidfile: "/var/run/gemstash.pid" })
      env = Gemstash::Env.new(config)
      expect(env.pidfile).to eq("/var/run/gemstash.pid")
    end
  end

  context "with a base path other than default" do
    let(:env) { Gemstash::Env.new }

    it "blocks access if it is not writable" do
      dir = Dir.mktmpdir
      FileUtils.remove_entry dir
      env.config = Gemstash::Configuration.new(config: { :base_path => dir })
      expect { env.base_path }.to raise_error("Base path '#{dir}' is not writable")
      expect { env.base_file("example.txt") }.to raise_error("Base path '#{dir}' is not writable")
    end

    it "defaults the log file to server.log" do
      env.config = Gemstash::Configuration.new(config: {})
      expect(env.log_file).to eq(env.base_file("server.log"))
    end

    it "can override the default log file location" do
      Dir.mktmpdir do |dir|
        log_file = File.join(dir, "server.log")
        env.config = Gemstash::Configuration.new(config: { :log_file => log_file })
        expect(env.log_file).to eq(env.base_file(log_file))
      end
    end
  end
end
