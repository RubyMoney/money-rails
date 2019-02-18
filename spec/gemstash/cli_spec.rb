require 'spec_helper'

RSpec.describe 'CLI executable', type: :aruba do
  let(:content) { 'Hello, Aruba!' }

  before do
    run_command('exe/gemstash')
  end

  # Full string
  it { expect(last_command_started).to have_output(content) }

  # Substring
  it { expect(last_command_started).to have_output(/Hello/) }
end