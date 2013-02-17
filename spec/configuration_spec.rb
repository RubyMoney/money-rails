require 'spec_helper'

describe "configuration" do

  describe "initializer" do

    it "sets default currency" do
      Money.default_currency.should == Money::Currency.new(:eur)
    end

    it "registers a custom currency" do
      Money::Currency.table.should include(:eu4)
    end

    it "adds exchange rates given in config initializer" do
      Money.us_dollar(100).exchange_to("CAD").should == Money.new(124, "CAD")
      Money.ca_dollar(100).exchange_to("USD").should == Money.new(80, "USD")
    end

    it "sets no_cents_if_whole value for formatted output globally" do
      # Disable the usage of I18n (to avoid default symbols for :en)
      Money.use_i18n = false

      value = Money.new(12345600, "EUR")
      mark = Money::Currency.find(:eur).decimal_mark
      value.format.should =~ /#{mark}/

      MoneyRails.no_cents_if_whole = true
      value.format.should_not =~ /#{mark}/
      value.format(no_cents_if_whole: false).should =~ /#{mark}/

      MoneyRails.no_cents_if_whole = false
      value.format.should =~ /#{mark}/
      value.format(no_cents_if_whole: true).should_not =~ /#{mark}/

      # Reset global settings
      MoneyRails.no_cents_if_whole = nil
      Money.use_i18n = true
    end

    it "sets symbol for formatted output globally" do
      value = Money.new(12345600, "EUR")
      symbol = Money::Currency.find(:eur).symbol
      value.format.should =~ /#{symbol}/

      MoneyRails.symbol = false
      value.format.should_not =~ /#{symbol}/
      value.format(symbol: true).should =~ /#{symbol}/

      MoneyRails.symbol = true
      value.format.should =~ /#{symbol}/
      value.format(symbol: false).should_not =~ /#{symbol}/

      # Reset global setting
      MoneyRails.symbol = nil
    end

    it "changes the amount and currency column settings based on the default currency" do
      old_currency = MoneyRails.default_currency
      MoneyRails.default_currency = :inr

      MoneyRails.amount_column[:postfix].should == "_#{MoneyRails.default_currency.subunit.downcase.pluralize}"
      MoneyRails.currency_column[:default].should == MoneyRails.default_currency.iso_code

      # Reset global setting
      MoneyRails.default_currency = old_currency
    end
    
  end
end
