require 'spec_helper'

describe "configuration" do

  describe "initializer" do

    it "sets default currency" do
      expect(Money.default_currency).to eq(Money::Currency.new(:eur))
    end

    it "registers a custom currency" do
      expect(Money::Currency.table).to include(:eu4)
    end

    it "adds exchange rates given in config initializer" do
      expect(Money.us_dollar(100).bank.get_rate('USD', 'CAD')).to eq(1.24515)
      expect(Money.ca_dollar(100).bank.get_rate('CAD', 'USD')).to eq(0.803115)
    end

    it "sets no_cents_if_whole value for formatted output globally" do
      # Enable formatting to depend only on currency (to avoid default symbols for :en)
      Money.locale_backend = :currency

      value = Money.new(12345600, "EUR")
      mark = Money::Currency.find(:eur).decimal_mark
      expect(value.format).to match(/#{mark}/)

      MoneyRails.no_cents_if_whole = true
      expect(value.format).not_to match(/#{mark}/)
      expect(value.format(no_cents_if_whole: false)).to match(/#{mark}/)

      MoneyRails.no_cents_if_whole = false
      expect(value.format).to match(/#{mark}/)
      expect(value.format(no_cents_if_whole: true)).not_to match(/#{mark}/)

      # Reset global settings
      MoneyRails.no_cents_if_whole = nil
      Money.locale_backend = :i18n
    end

    it "sets symbol for formatted output globally" do
      value = Money.new(12345600, "EUR")
      symbol = Money::Currency.find(:eur).symbol
      expect(value.format).to match(/#{symbol}/)

      MoneyRails.symbol = false
      expect(value.format).not_to match(/#{symbol}/)
      expect(value.format(symbol: true)).to match(/#{symbol}/)

      MoneyRails.symbol = true
      expect(value.format).to match(/#{symbol}/)
      expect(value.format(symbol: false)).not_to match(/#{symbol}/)

      # Reset global setting
      MoneyRails.symbol = nil
    end

    it "sets the location of the negative sign for formatted output globally" do
      value = Money.new(-12345600, "EUR")
      symbol = Money::Currency.find(:eur).symbol
      expect(value.format).to match(/#{symbol}-/)

      MoneyRails.sign_before_symbol = false
      expect(value.format).to match(/#{symbol}-/)
      expect(value.format(sign_before_symbol: false)).to match(/#{symbol}-/)

      MoneyRails.sign_before_symbol = true
      expect(value.format).to match(/-#{symbol}/)
      expect(value.format(sign_before_symbol: true)).to match(/-#{symbol}/)

      # Reset global setting
      MoneyRails.sign_before_symbol = nil
    end

    it "passes through arbitrary format options" do
      value = Money.new(-12345600, "EUR")
      symbol = Money::Currency.find(:eur).symbol

      MoneyRails.default_format = {symbol_position: :after}
      expect(value.format).to match(/#{symbol}\z/)

      # Override with "classic" format options for backward compatibility
      MoneyRails.default_format = {sign_before_symbol: :false}
      MoneyRails.sign_before_symbol = true
      expect(value.format).to match(/-#{symbol}/)

      # Reset global settings
      MoneyRails.sign_before_symbol = nil
      MoneyRails.default_format = nil
    end

    it "changes the amount and currency column settings based on the default currency" do
      old_currency = MoneyRails.default_currency
      MoneyRails.default_currency = :inr

      expect(MoneyRails.default_currency.subunit).to eq 'Paisa'
      expect(MoneyRails.amount_column[:postfix]).to eq("_cents") # not localized

      expect(MoneyRails.currency_column[:default]).to eq(MoneyRails.default_currency.iso_code)

      # Reset global setting
      MoneyRails.default_currency = old_currency
    end

    it "accepts default currency which doesn't have minor unit" do
      old_currency = MoneyRails.default_currency

      expect {
        MoneyRails.default_currency = :jpy
      }.to_not raise_error

      expect(MoneyRails.amount_column[:postfix]).to eq("_cents")

      # Reset global setting
      MoneyRails.default_currency = old_currency
    end

    it "assigns a default bank" do
      old_bank = MoneyRails.default_bank

      bank = Money::Bank::VariableExchange.new
      MoneyRails.default_bank = bank
      expect(Money.default_bank).to eq(bank)

      MoneyRails.default_bank = old_bank
    end

    describe "rounding mode" do
      [BigDecimal::ROUND_UP, BigDecimal::ROUND_DOWN, BigDecimal::ROUND_HALF_UP, BigDecimal::ROUND_HALF_DOWN,
       BigDecimal::ROUND_HALF_EVEN, BigDecimal::ROUND_CEILING, BigDecimal::ROUND_FLOOR].each do |mode|
        context "when set to #{mode}" do
          it "sets Money.rounding mode to #{mode}" do
            MoneyRails.rounding_mode = mode
            expect(Money.rounding_mode).to eq(mode)
          end
        end
      end

      context "when passed an invalid value" do
        it "should raise an ArgumentError" do
          expect(lambda{MoneyRails.rounding_mode = "booyakasha"}).to raise_error(ArgumentError, 'booyakasha is not a valid rounding mode')
        end
      end
    end

  end
end
