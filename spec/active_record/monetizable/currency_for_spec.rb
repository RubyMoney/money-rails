# encoding: utf-8

require 'spec_helper'

if defined? ActiveRecord
  describe MoneyRails::ActiveRecord::Monetizable do
    describe "#currency_for" do
      context "when detecting currency based on different conditions" do
        it "detects currency based on instance currency name" do
          product = Product.new(sale_price_currency_code: 'CAD')
          currency = product.send(:currency_for, :sale_price, :sale_price_currency_code, nil)

          expect(currency).to be_an_instance_of(Money::Currency)
          expect(currency.iso_code).to eq('CAD')
        end

        it "detects currency based on currency passed as a block" do
          product = Product.new
          currency = product.send(:currency_for, :lambda_price, nil, ->(_) { 'CAD' })

          expect(currency).to be_an_instance_of(Money::Currency)
          expect(currency.iso_code).to eq('CAD')
        end

        it "detects currency based on currency passed explicitly" do
          product = Product.new
          currency = product.send(:currency_for, :bonus, nil, 'CAD')

          expect(currency).to be_an_instance_of(Money::Currency)
          expect(currency.iso_code).to eq('CAD')
        end
      end

      context "when falling back to a default or registered currency" do
        it "falls back to a registered currency" do
          product = Product.new
          currency = product.send(:currency_for, :amount, nil, nil)
          expected_currency = Product.currency

          expect(expected_currency).to be_an_instance_of(Money::Currency)
          expect(currency).to eq(expected_currency)
        end

        it "falls back to a default currency" do
          transaction = Transaction.new
          currency = transaction.send(:currency_for, :amount, nil, nil)
          expected_currency = Money.default_currency

          expect(expected_currency).to be_an_instance_of(Money::Currency)
          expect(currency).to eq(expected_currency)
        end
      end
    end
  end
end
