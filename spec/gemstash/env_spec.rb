require "spec_helper"

describe Gemstash::Env do
  context "with a base path other than default" do
    it "blocks access if it is not writable" do
      dir = Dir.mktmpdir
      FileUtils.remove_entry dir
      Gemstash::Env.config = Gemstash::Configuration.new(config: { :base_path => dir })
      expect { Gemstash::Env.base_path }.to raise_error("Base path '#{dir}' is not writable")
      expect { Gemstash::Env.base_file("example.txt") }.to raise_error("Base path '#{dir}' is not writable")
    end
  end
end
