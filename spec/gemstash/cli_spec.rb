# frozen_string_literal: true

require "spec_helper"

RSpec.describe "CLI executable", type: :aruba do
  before do
    run_command("exe/gemstash --version")
  end

  it { expect(last_command_started).to have_output(/Gemstash version \d\.\d\.\d/) }
end
