# encoding: utf-8

require 'spec_helper'

require_relative 'money_helpers'

if defined? ActiveRecord
  describe MoneyRails::ActiveRecord::Monetizable do
    include MoneyHelpers

    describe ".register_currency" do
      it "attaches currency at model level" do
        expect_money_currency_is(Product, :usd)
        expect_money_currency_is(DummyProduct, :gbp)
      end
    end
  end
end
