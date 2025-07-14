# encoding: utf-8

require 'spec_helper'

require_relative 'money_helpers'

if defined? ActiveRecord
  class InheritedMonetizeProduct < Product
    monetize :special_price_cents
  end

  describe MoneyRails::ActiveRecord::Monetizable do
    include MoneyHelpers

    describe ".monetized_attributes" do
      def assert_monetized_attributes(monetized_attributes, expected_attributes)
        expect(monetized_attributes).to include expected_attributes
        expect(expected_attributes).to include monetized_attributes
        expect(monetized_attributes.size).to eql expected_attributes.size

        monetized_attributes.keys.each do |key|
          expect(key.is_a? String).to be_truthy
        end
      end

      it "should be inherited by subclasses" do
        assert_monetized_attributes(Sub.monetized_attributes, Product.monetized_attributes)
      end

      it "should be inherited by subclasses with new monetized attribute" do
        assert_monetized_attributes(
          InheritedMonetizeProduct.monetized_attributes,
          Product.monetized_attributes.merge(special_price: "special_price_cents")
        )
      end
    end

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

      context 'without a default currency' do
        let(:product) { OtherProduct.new }

        around do |example|
          default_currency = Money.default_currency
          Money.default_currency = nil

          example.run

          Money.default_currency = default_currency
        end

        it "errors a NoCurrency Error" do
          expect do
            product.write_monetized :price, :price_cents, 10.5, false, nil, {}
          end.to raise_error(Money::Currency::NoCurrency)
        end
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
