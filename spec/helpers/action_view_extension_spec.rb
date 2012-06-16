require 'spec_helper'

describe 'MoneyRails::ActionViewExtension' do
  describe '#currency_symbol' do
    subject { helper.currency_symbol }
    it { should be_a String }
    it { should include Money.default_currency.symbol }
  end
end
