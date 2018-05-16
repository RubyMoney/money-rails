require 'spec_helper'

describe 'MoneyRails::ActionViewExtension', type: :helper do
  describe '#currency_symbol' do
    subject { helper.currency_symbol }
    it { is_expected.to be_a String }
    it { is_expected.to include Money.default_currency.symbol }
  end

  describe '#humanized_money' do
    let(:money_object){ Money.new(12500) }
    let(:options) { {} }
    subject { helper.humanized_money money_object, options }
    it { is_expected.to be_a String }
    it { is_expected.not_to include Money.default_currency.symbol }
    it { is_expected.not_to include Money.default_currency.decimal_mark }

    context 'with symbol options' do
      let(:options) { { symbol: true } }
      it { is_expected.to include Money.default_currency.symbol }
    end

    context 'with deprecated symbol' do
      let(:options) { true }
      before(:each) do
        expect(helper).to receive(:warn)
      end
      it { is_expected.to include Money.default_currency.symbol }
    end

    context 'with a currency with an alternate symbol' do
      let(:money_object) { Money.new(125_00, 'SGD') }

      context 'with symbol options' do
        let(:options) { { symbol: true } }
        it { is_expected.to include Money::Currency.new(:sgd).symbol }

        context 'with disambiguate options' do
          let(:options) { { symbol: true, disambiguate: true } }
          it { is_expected.to include Money::Currency.new(:sgd).disambiguate_symbol }
        end
      end
    end
  end

  describe '#humanized_money_with_symbol' do
    subject { helper.humanized_money_with_symbol Money.new(12500) }
    it { is_expected.to be_a String }
    it { is_expected.not_to include Money.default_currency.decimal_mark }
    it { is_expected.to include Money.default_currency.symbol }
  end

  describe '#money_without_cents' do
    let(:options) { {} }
    subject { helper.money_without_cents Money.new(12500), options }
    it { is_expected.to be_a String }
    it { is_expected.not_to include Money.default_currency.symbol }
    it { is_expected.not_to include Money.default_currency.decimal_mark }

    context 'with deprecated symbol' do
      let(:options) { true }
      before(:each) do
        expect(helper).to receive(:warn)
      end
      it { is_expected.to include Money.default_currency.symbol }
    end
  end

  describe '#money_without_cents_and_with_symbol' do
    subject { helper.money_without_cents_and_with_symbol Money.new(12500) }
    it { is_expected.to be_a String }
    it { is_expected.not_to include Money.default_currency.decimal_mark }
    it { is_expected.to include Money.default_currency.symbol }
    it { is_expected.not_to include "00" }
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
        it { is_expected.to be_a String }
        it { is_expected.not_to include Money.default_currency.decimal_mark }
        it { is_expected.not_to include Money.default_currency.symbol }
        it { is_expected.to include "00" }
      end

      describe '#humanized_money_with_symbol' do
        subject { helper.humanized_money_with_symbol Money.new(12500) }
        it { is_expected.to be_a String }
        it { is_expected.not_to include Money.default_currency.decimal_mark }
        it { is_expected.to include Money.default_currency.symbol }
        it { is_expected.to include "00" }
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
        it { is_expected.to be_a String }
        it { is_expected.not_to include Money.default_currency.decimal_mark }
        it { is_expected.not_to include Money.default_currency.symbol }
        it { is_expected.not_to include "00" }
      end

      describe '#humanized_money_with_symbol' do
        subject { helper.humanized_money_with_symbol Money.new(12500) }
        it { is_expected.to be_a String }
        it { is_expected.not_to include Money.default_currency.decimal_mark }
        it { is_expected.to include Money.default_currency.symbol }
        it { is_expected.not_to include "00" }
      end
    end

    context 'with no_cents_if_whole: false' do

      before do
        MoneyRails.configure do |config|
          config.no_cents_if_whole = false
        end
      end

      around(:each) do |example|
        I18n.with_locale(:it) do
          example.run
        end
      end

      describe '#humanized_money' do
        subject { helper.humanized_money Money.new(12500) }
        it { is_expected.to be_a String }
        it { is_expected.to include Money.default_currency.decimal_mark }
        it { is_expected.not_to include Money.default_currency.symbol }
        it { is_expected.to include "00" }
      end

      describe '#humanized_money_with_symbol' do
        subject { helper.humanized_money_with_symbol Money.new(12500) }
        it { is_expected.to be_a String }
        it { is_expected.to include Money.default_currency.decimal_mark }
        it { is_expected.to include Money.default_currency.symbol }
        it { is_expected.to include "00" }
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
        it { is_expected.to be_a String }
        it { is_expected.not_to include Money.default_currency.decimal_mark }
        it { is_expected.not_to include Money.default_currency.symbol }
        it { is_expected.not_to include "00" }
      end

      describe '#humanized_money_with_symbol' do
        subject { helper.humanized_money_with_symbol Money.new(12500) }
        it { is_expected.to be_a String }
        it { is_expected.not_to include Money.default_currency.decimal_mark }
        it { is_expected.to include Money.default_currency.symbol }
        it { is_expected.not_to include "00" }
      end
    end


  end

end
