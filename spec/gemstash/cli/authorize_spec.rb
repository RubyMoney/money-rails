# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require "yaml"

RSpec.describe Gemstash::CLI::Authorize do
  before do
    # Don't let the environment change, else we get a separate test db
    # connection, which messes up the tests
    allow(Gemstash::Env).to receive(:current=).and_return(nil)
    # Don't let the config change, so we don't reload the DB or anything
    allow_any_instance_of(Gemstash::Env).to receive(:config=).and_return(nil)
  end

  let(:cli) do
    @said = ""
    result = double(:options => cli_options)

    allow(result).to receive(:say) do |x|
      @said += "#{x}\n"
      nil
    end

    allow(result).to receive(:set_color) {|x| x }
    result
  end

  let(:cli_options) { {} }

  context "authorizing with just the auth key" do
    let(:cli_options) { { :key => "auth-key" } }

    it "authorizes the key for all permissions" do
      Gemstash::CLI::Authorize.new(cli).run
      expect(Gemstash::Authorization["auth-key"].all?).to be_truthy
    end
  end

  context "authorizing with the auth key and permissions" do
    let(:cli_options) { { :key => "auth-key" } }

    it "authorizes the key for just the given permissions" do
      Gemstash::CLI::Authorize.new(cli, "push", "yank").run
      auth = Gemstash::Authorization["auth-key"]
      expect(auth.all?).to be_falsey
      expect(auth.push?).to be_truthy
      expect(auth.yank?).to be_truthy
    end
  end

  context "authorizing without specifying the key" do
    it "outputs the new key and authorizes for all permissions" do
      expect(SecureRandom).to receive(:hex).and_return("new-auth-key")
      Gemstash::CLI::Authorize.new(cli).run
      expect(@said).to include("new-auth-key")
      expect(Gemstash::Authorization["new-auth-key"].all?).to be_truthy
    end
  end

  context "authorizing without specifying the key and with permissions" do
    it "outputs the new key and authorizes for the given permissions" do
      expect(SecureRandom).to receive(:hex).and_return("new-auth-key")
      Gemstash::CLI::Authorize.new(cli, "push", "yank").run
      expect(@said).to include("new-auth-key")
      auth = Gemstash::Authorization["new-auth-key"]
      expect(auth.all?).to be_falsey
      expect(auth.push?).to be_truthy
      expect(auth.yank?).to be_truthy
    end
  end

  context "a random auth key coming up more than once" do
    before do
      Gemstash::Authorization.authorize("existing-auth-key", "all")
    end

    it "continues to generate a key until a unique one is generated" do
      expect(SecureRandom).to receive(:hex).and_return("existing-auth-key")
      expect(SecureRandom).to receive(:hex).and_return("existing-auth-key")
      expect(SecureRandom).to receive(:hex).and_return("new-auth-key")
      Gemstash::CLI::Authorize.new(cli, "push", "yank").run
      expect(@said).to include("new-auth-key")
      expect(Gemstash::Authorization["existing-auth-key"].all?).to be_truthy
      auth = Gemstash::Authorization["new-auth-key"]
      expect(auth.all?).to be_falsey
      expect(auth.push?).to be_truthy
      expect(auth.yank?).to be_truthy
    end
  end

  context "authorizing an existing auth key" do
    let(:cli_options) { { :key => "auth-key" } }

    before do
      Gemstash::Authorization.authorize("auth-key", %w[yank])
    end

    it "updates the permissions" do
      Gemstash::CLI::Authorize.new(cli, "push", "yank").run
      auth = Gemstash::Authorization["auth-key"]
      expect(auth.all?).to be_falsey
      expect(auth.push?).to be_truthy
      expect(auth.yank?).to be_truthy
    end
  end

  context "with the --remove option" do
    let(:cli_options) { { :key => "auth-key", :remove => true } }

    before do
      Gemstash::Authorization.authorize("auth-key", %w[yank])
    end

    it "removes the authorization" do
      Gemstash::CLI::Authorize.new(cli).run
      expect(Gemstash::Authorization["auth-key"]).to be_nil
    end
  end

  context "with invalid permissions" do
    let(:cli_options) { { :key => "auth-key" } }

    it "gives the user an error" do
      expect { Gemstash::CLI::Authorize.new(cli, "all").run }.to raise_error(Gemstash::CLI::Error)
      expect { Gemstash::CLI::Authorize.new(cli, "invalid").run }.to raise_error(Gemstash::CLI::Error)
      expect(Gemstash::Authorization["auth-key"]).to be_nil
    end
  end

  context "with --remove option and permissions" do
    let(:cli_options) { { :key => "auth-key", :remove => true } }

    before do
      Gemstash::Authorization.authorize("auth-key", %w[yank])
    end

    it "gives the user an error" do
      expect { Gemstash::CLI::Authorize.new(cli, "push").run }.to raise_error(Gemstash::CLI::Error)
      expect(Gemstash::Authorization["auth-key"]).to be
    end
  end

  context "with --remove option and no --key" do
    let(:cli_options) { { :remove => true } }

    it "gives the user an error" do
      expect { Gemstash::CLI::Authorize.new(cli).run }.to raise_error(Gemstash::CLI::Error)
    end
  end
end
