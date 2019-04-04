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
end
