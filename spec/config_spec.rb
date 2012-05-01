require 'spec_helper'

describe "configuration" do

  describe "initializer" do

    it "sets default currency" do
      Money.default_currency.should == Money::Currency.new(:eur)
    end

    it "registers a custom currency" do
      Money::Currency.table.should include(:eu4)
    end
  end
end
