# encoding: utf-8

require 'spec_helper'

require_relative 'money_helpers'

if defined? ActiveRecord
  describe MoneyRails::ActiveRecord::Monetizable do
    include MoneyHelpers

    describe "#currency_for" do
      context "when detecting currency based on different conditions" do
        it "detects currency based on instance currency name" do
          product = Product.new(sale_price_currency_code: 'CAD')
          currency = product.send(:currency_for, :sale_price, :sale_price_currency_code, nil)

          expect_to_be_a_currency_instance(currency)
          expect_currency_iso_code(currency, 'CAD')
        end

        it "detects currency based on currency passed as a block" do
          product = Product.new
          currency = product.send(:currency_for, :lambda_price, nil, ->(_) { 'CAD' })

          expect_to_be_a_currency_instance(currency)
          expect_currency_iso_code(currency, 'CAD')
        end

        it "detects currency based on currency passed explicitly" do
          product = Product.new
          currency = product.send(:currency_for, :bonus, nil, 'CAD')

          expect_to_be_a_currency_instance(currency)
          expect_currency_iso_code(currency, 'CAD')
        end
      end

      context "when falling back to a default or registered currency" do
        it "falls back to a registered currency" do
          product = Product.new
          currency = product.send(:currency_for, :amount, nil, nil)

          expect_equal_currency(currency, Product.currency)
        end

        it "falls back to a default currency" do
          transaction = Transaction.new
          currency = transaction.send(:currency_for, :amount, nil, nil)

          expect_equal_currency(currency, Money.default_currency)
        end
      end
    end
  end
end
