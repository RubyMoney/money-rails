$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
ENV["RACK_ENV"] = "test"
require "gemstash"
require "dalli"
require "support/matchers"

RSpec.configure do |config|
  config.before(:each) do
    Dalli::Client.new.flush
  end

  config.raise_errors_for_deprecations!
end
