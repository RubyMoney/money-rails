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
  end
end
