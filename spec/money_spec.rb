# encoding: utf-8

require 'spec_helper'

describe 'Money overrides' do
  describe '.default_formatting_rules' do
    it 'uses defauts set as individual options' do
      allow(MoneyRails::Configuration).to receive(:symbol).and_return('£')

      expect(Money.default_formatting_rules).to include(symbol: '£')
    end

    it 'ignores individual options that are nil' do
      allow(MoneyRails::Configuration).to receive(:symbol).and_return(nil)

      expect(Money.default_formatting_rules.keys).not_to include(:symbol)
    end

    it 'includes default_format options' do
      allow(MoneyRails::Configuration).to receive(:default_format).and_return(symbol: '£')

      expect(Money.default_formatting_rules).to include(symbol: '£')
    end

    it 'gives priority to original defaults' do
      allow(Money).to receive(:orig_default_formatting_rules).and_return(symbol: '£')
      allow(MoneyRails::Configuration).to receive(:symbol).and_return('€')
      allow(MoneyRails::Configuration).to receive(:default_format).and_return(symbol: '€')

      expect(Money.default_formatting_rules).to include(symbol: '£')
    end
  end

  describe '#to_hash' do
    it 'returns a hash with JSON representation' do
      expect(Money.new(9_99, 'EUR').to_hash).to eq(cents: 9_99, currency_iso: 'EUR')
      expect(Money.zero('USD').to_hash).to eq(cents: 0, currency_iso: 'USD')
    end
  end
end
