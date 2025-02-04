# encoding: utf-8

require 'spec_helper'

require_relative 'money_helpers'
require_relative 'shared_contexts'

if defined? ActiveRecord
  describe MoneyRails::ActiveRecord::Monetizable do
    include MoneyHelpers

    include_context "monetizable product setup"

    describe "#write_monetized" do
      let(:value) { Money.new(1_000, 'LVL') }

      it "sets monetized attribute's value to Money object" do
        product.write_monetized :price, :price_cents, value, false, nil, {}

        expect_to_be_a_money_instance(product.price)
        expect_money_attribute_cents_value(product, :price, value.cents)
        # Because :price does not have a column for currency
        expect_equal_money_currency(product.price, Product)
      end

      it "sets monetized attribute's value from a given Fixnum" do
        product.write_monetized :price, :price_cents, 10, false, nil, {}

        expect_to_be_a_money_instance(product.price)
        expect_money_attribute_cents_value(product, :price, 1000)
      end

      it "sets monetized attribute's value from a given Float" do
        product.write_monetized :price, :price_cents, 10.5, false, nil, {}

        expect_to_be_a_money_instance(product.price)
        expect_money_attribute_cents_value(product, :price, 1050)
      end

      it "resets monetized attribute when given blank input" do
        product.write_monetized :price, :price_cents, nil, false, nil, { allow_nil: true }

        expect(product.price).to eq(nil)
      end

      it "sets monetized attribute to 0 when given a blank value" do
        currency = product.price.currency
        product.write_monetized :price, :price_cents, nil, false, nil, {}

        expect(product.price.amount).to eq(0)
        expect_equal_currency(product.price.currency, currency)
      end

      it "does not memoize monetized attribute's value if currency is read-only" do
        product.write_monetized :price, :price_cents, value, false, nil, {}

        price = product.instance_variable_get('@price')

        expect_to_be_a_money_instance(price)
        expect(price.amount).not_to eq(value.amount)
      end

      describe "instance_currency_name" do
        it "updates instance_currency_name attribute" do
          product.write_monetized :sale_price, :sale_price_amount, value, false, :sale_price_currency_code, {}

          expect_equal_money(product.sale_price, value)
          expect(product.sale_price_currency_code).to eq('LVL')
        end

        it "memoizes monetized attribute's value with currency" do
          product.write_monetized :sale_price, :sale_price_amount, value, false, :sale_price_currency_code, {}

          expect_equal_money(product.instance_variable_get('@sale_price'), value)
        end

        it "ignores empty instance_currency_name" do
          product.write_monetized :sale_price, :sale_price_amount, value, false, '', {}

          expect(product.sale_price.amount).to eq(value.amount)
          expect_equal_money_currency(product.sale_price, Product)
        end

        it "ignores instance_currency_name that model does not respond to" do
          product.write_monetized :sale_price, :sale_price_amount, value, false, :non_existing_currency, {}

          expect(product.sale_price.amount).to eq(value.amount)
          expect_equal_money_currency(product.sale_price, Product)
        end
      end

      describe "error handling" do
        let!(:old_price_value) { product.price }

        it "ignores values that do not implement to_money method" do
          product.write_monetized :price, :price_cents, [10], false, nil, {}

          expect_equal_money(product.price, old_price_value)
        end

        context "raise_error_on_money_parsing enabled" do
          before { MoneyRails.raise_error_on_money_parsing = true }
          after { MoneyRails.raise_error_on_money_parsing = false }

          it "raises a MoneyRails::Error when given an invalid value" do
            expect {
              product.write_monetized :price, :price_cents, '10-50', false, nil, {}
            }.to raise_error(MoneyRails::Error)
          end

          it "raises a MoneyRails::Error error when trying to set invalid currency" do
            allow(product).to receive(:currency_for_price).and_return('INVALID_CURRENCY')
            expect {
              product.write_monetized :price, :price_cents, 10, false, nil, {}
            }.to raise_error(MoneyRails::Error)
          end
        end

        context "raise_error_on_money_parsing disabled" do
          it "ignores when given invalid value" do
            product.write_monetized :price, :price_cents, '10-50', false, nil, {}

            expect_equal_money(product.price, old_price_value)
          end

          it "raises a MoneyRails::Error error when trying to set invalid currency" do
            allow(product).to receive(:currency_for_price).and_return('INVALID_CURRENCY')
            product.write_monetized :price, :price_cents, 10, false, nil, {}

            # Cannot use public accessor here because currency_for_price is stubbed
            expect_equal_money(product.instance_variable_get('@price'), old_price_value)
          end
        end
      end
    end
  end
end
