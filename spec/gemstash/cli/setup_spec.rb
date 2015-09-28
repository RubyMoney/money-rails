require "spec_helper"
require "yaml"

describe Gemstash::CLI::Setup do
  let(:cli) do
    result = double(:options => cli_options, :say => nil)
    allow(result).to receive(:set_color) {|x| x }
    result
  end

  let(:cli_options) do
    {
      :redo => false,
      :config_file => File.join(TEST_BASE_PATH, "setup_spec_config.yml")
    }
  end

  context "accepting all defaults" do
    it "saves the config with defaults" do
      allow(cli).to receive(:ask).and_return("")
      expect(File.exist?(cli_options[:config_file])).to be_falsey
      Gemstash::CLI::Setup.new(cli).run
      expect(File.exist?(cli_options[:config_file])).to be_truthy
      config = YAML.load_file(cli_options[:config_file])

      config.each do |key, value|
        expect(value).to eq(Gemstash::Configuration::DEFAULTS[key])
      end
    end
  end
end
