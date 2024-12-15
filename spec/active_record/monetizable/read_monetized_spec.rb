# encoding: utf-8

require 'spec_helper'

require_relative 'money_helpers'
require_relative 'shared_contexts'

if defined? ActiveRecord
  describe MoneyRails::ActiveRecord::Monetizable do
    include MoneyHelpers

    include_context "monetizable product setup"

    describe "#read_monetized" do
      context "when reading monetized attributes" do
        let(:reduced_price) { product.read_monetized(:reduced_price, :reduced_price_cents) }

        it "returns a Money object for monetized attribute" do
          expect_to_be_a_money_instance(reduced_price)
        end

        it "returns monetized attribute with correct amount and currency" do
          expect_equal_money_instance(reduced_price, amount: product.reduced_price_cents, currency: product.reduced_price_currency)
        end
      end

      describe "memoizing monetized attribute values" do
        it "memoizes monetized attribute's value" do
          product.instance_variable_set '@reduced_price', nil
          reduced_price = product.read_monetized(:reduced_price, :reduced_price_cents)
          memoized_reduced_price = product.instance_variable_get('@reduced_price')

          expect_equal_money(memoized_reduced_price, reduced_price)
        end

        context "when resetting memoized values" do
          it "resets the memoized value when the amount changes" do
            old_reduced_price = product.read_monetized(:reduced_price, :reduced_price_cents)
            product.reduced_price_cents = 100
            new_reduced_price = product.read_monetized(:reduced_price, :reduced_price_cents)

            expect(new_reduced_price).not_to eq(old_reduced_price)
          end

          it "resets the memoized value when the currency changes" do
            old_reduced_price = product.read_monetized(:reduced_price, :reduced_price_cents)
            product.reduced_price_currency = 'CAD'
            new_reduced_price = product.read_monetized(:reduced_price, :reduced_price_cents)

            expect(new_reduced_price).not_to eq(old_reduced_price)
          end
        end
      end

      context "with preserve_user_input enabled" do
        around(:each) do |example|
          MoneyRails::Configuration.preserve_user_input = true
          example.run
          MoneyRails::Configuration.preserve_user_input = false
        end

        it "has no effect if validation passes" do
          product.price = '14'

          expect(product.save).to be_truthy
          expect(product.read_monetized(:price, :price_cents).to_s).to eq('14.00')
        end

        it "preserves user input if validation fails" do
          product.price = '14,0'

          expect(product.save).to be_falsy
          expect(product.read_monetized(:price, :price_cents).to_s).to eq('14,0')
        end
      end

      context "with a monetized attribute that is nil" do
        let(:service) { Service.create(discount_cents: nil) }
        let(:default_currency_lambda) { double("Default Currency Fallback") }
        subject { service.read_monetized(:discount, :discount_cents, options) }

        around(:each) do |example|
          service # Instantiate instance which relies on Money.default_currency
          original_default_currency = Money.default_currency
          Money.default_currency = -> { default_currency_lambda.read_currency }
          example.run
          Money.default_currency = original_default_currency
        end

        context "when allow_nil enabled" do
          let(:options) { { allow_nil: true } }

          it "does not attempt to read the fallback default currency" do
            expect(default_currency_lambda).not_to receive(:read_currency)
            subject
          end
        end
      end
    end
  end
end
