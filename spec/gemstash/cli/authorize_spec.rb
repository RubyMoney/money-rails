require "spec_helper"
require "yaml"

describe Gemstash::CLI::Authorize do
  before do
    # Don't let the environment change, else we get a separate test db
    # connection, which messes up the tests
    allow(Gemstash::Env).to receive(:current=).and_return(nil)
    # Don't let the config change, so we don't reload the DB or anything
    allow_any_instance_of(Gemstash::Env).to receive(:config=).and_return(nil)
  end

  let(:cli) do
    result = double(:options => cli_options, :say => nil)
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
      expect(auth.unyank?).to be_falsey
    end
  end

  context "authorizing without specifying the key" do
    it "outputs the new key and authorizes for all permissions"
  end

  context "authorizing without specifying the key and with permissions" do
    it "outputs the new key and authorizes for the given permissions"
  end

  context "authorizing an existing auth key" do
    let(:cli_options) { { :key => "auth-key" } }

    before do
      Gemstash::Authorization.authorize("auth-key", %w(yank unyank))
    end

    it "updates the permissions" do
      Gemstash::CLI::Authorize.new(cli, "push", "yank").run
      auth = Gemstash::Authorization["auth-key"]
      expect(auth.all?).to be_falsey
      expect(auth.push?).to be_truthy
      expect(auth.yank?).to be_truthy
      expect(auth.unyank?).to be_falsey
    end
  end

  context "with the --remove option" do
    it "removes the authorization"
  end

  context "with invalid permissions" do
    it "gives the user an error"
  end

  context "with --remove option and permissions" do
    it "gives the user an error"
  end
end
