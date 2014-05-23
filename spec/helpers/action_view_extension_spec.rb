require 'spec_helper'

describe 'MoneyRails::ActionViewExtension' do
  describe '#currency_symbol' do
    subject { helper.currency_symbol }
    it { should be_a String }
    it { should include Money.default_currency.symbol }
  end

  describe '#humanized_money' do
    let(:options) { {} }
    subject { helper.humanized_money Money.new(12500), options }
    it { should be_a String }
    it { should_not include Money.default_currency.symbol }
    it { should_not include Money.default_currency.decimal_mark }

    context 'with symbol options' do
      let(:options) { { :symbol => true } }
      it { should include Money.default_currency.symbol }
    end

    context 'with deprecated symbol' do
      let(:options) { true }
      before(:each) do
        helper.should_receive(:warn)
      end
      it { should include Money.default_currency.symbol }
    end
  end

  describe '#humanized_money_with_symbol' do
    subject { helper.humanized_money_with_symbol Money.new(12500) }
    it { should be_a String }
    it { should_not include Money.default_currency.decimal_mark }
    it { should include Money.default_currency.symbol }
  end

  describe '#money_without_cents' do
    let(:options) { {} }
    subject { helper.money_without_cents Money.new(12500), options }
    it { should be_a String }
    it { should_not include Money.default_currency.symbol }
    it { should_not include Money.default_currency.decimal_mark }

    context 'with deprecated symbol' do
      let(:options) { true }
      before(:each) do
        helper.should_receive(:warn)
      end
      it { should include Money.default_currency.symbol }
    end
  end

  describe '#money_without_cents_and_with_symbol' do
    subject { helper.money_without_cents_and_with_symbol Money.new(12500) }
    it { should be_a String }
    it { should_not include Money.default_currency.decimal_mark }
    it { should include Money.default_currency.symbol }
    it { should_not include "00" }
  end

  context 'respects MoneyRails::Configuration settings' do
    context 'with no_cents_if_whole: false' do

      before do
        MoneyRails.configure do |config|
          config.no_cents_if_whole = false
        end
      end

      describe '#humanized_money' do
        subject { helper.humanized_money Money.new(12500) }
        it { should be_a String }
        it { should_not include Money.default_currency.decimal_mark }
        it { should_not include Money.default_currency.symbol }
        it { should include "00" }
      end

      describe '#humanized_money_with_symbol' do
        subject { helper.humanized_money_with_symbol Money.new(12500) }
        it { should be_a String }
        it { should_not include Money.default_currency.decimal_mark }
        it { should include Money.default_currency.symbol }
        it { should include "00" }
      end
    end

    context 'with no_cents_if_whole: nil' do

      before do
        MoneyRails.configure do |config|
          config.no_cents_if_whole = nil
        end
      end

      describe '#humanized_money' do
        subject { helper.humanized_money Money.new(12500) }
        it { should be_a String }
        it { should_not include Money.default_currency.decimal_mark }
        it { should_not include Money.default_currency.symbol }
        it { should_not include "00" }
      end

      describe '#humanized_money_with_symbol' do
        subject { helper.humanized_money_with_symbol Money.new(12500) }
        it { should be_a String }
        it { should_not include Money.default_currency.decimal_mark }
        it { should include Money.default_currency.symbol }
        it { should_not include "00" }
      end
    end

    context 'with no_cents_if_whole: true' do

      before do
        MoneyRails.configure do |config|
          config.no_cents_if_whole = true
        end
      end

      describe '#humanized_money' do
        subject { helper.humanized_money Money.new(12500) }
        it { should be_a String }
        it { should_not include Money.default_currency.decimal_mark }
        it { should_not include Money.default_currency.symbol }
        it { should_not include "00" }
      end

      describe '#humanized_money_with_symbol' do
        subject { helper.humanized_money_with_symbol Money.new(12500) }
        it { should be_a String }
        it { should_not include Money.default_currency.decimal_mark }
        it { should include Money.default_currency.symbol }
        it { should_not include "00" }
      end
    end


  end

end
