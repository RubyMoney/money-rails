# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gemstash do
  it "has a version number" do
    expect(Gemstash::VERSION).not_to be nil
  end
end
