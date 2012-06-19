require 'spec_helper'

describe 'MoneyRails::ActionViewExtension' do
  describe '#currency_symbol' do
    subject { helper.currency_symbol }
    it { should be_a String }
    it { should include Money.default_currency.symbol }
  end

  describe '#humanized_money' do
    subject { helper.humanized_money Money.new(12500) }
    it { should be_a String }
    it { should_not include Money.default_currency.symbol }
    it { should_not include Money.default_currency.decimal_mark }
  end

  describe '#humanized_money_with_symbol' do
    subject { helper.humanized_money_with_symbol Money.new(12500) }
    it { should be_a String }
    it { should_not include Money.default_currency.decimal_mark }
    it { should include Money.default_currency.symbol }
  end

  describe '#money_without_cents' do
    subject { helper.money_without_cents Money.new(12500) }
    it { should be_a String }
    it { should_not include Money.default_currency.symbol }
    it { should_not include Money.default_currency.decimal_mark }
  end

  describe '#money_without_cents_and_with_symbol' do
    subject { helper.money_without_cents_and_with_symbol Money.new(12500) }
    it { should be_a String }
    it { should_not include Money.default_currency.decimal_mark }
    it { should include Money.default_currency.symbol }
  end

end
