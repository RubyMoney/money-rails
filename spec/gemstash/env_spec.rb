require "spec_helper"

describe Gemstash::Env do
  context "with a base path other than default" do
    let(:env) { Gemstash::Env.new }

    it "blocks access if it is not writable" do
      dir = Dir.mktmpdir
      FileUtils.remove_entry dir
      env.config = Gemstash::Configuration.new(config: { :base_path => dir })
      expect { env.base_path }.to raise_error("Base path '#{dir}' is not writable")
      expect { env.base_file("example.txt") }.to raise_error("Base path '#{dir}' is not writable")
    end
  end
end
