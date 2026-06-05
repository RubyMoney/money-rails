# frozen_string_literal: true

require "spec_helper"

if defined? ActiveRecord
  describe MoneyRails::ActiveRecord::Monetizable do
    let(:product) do
      Product.create(
        price_cents: 3000,
        discount: 150,
        bonus_cents: 200,
        optional_price: 100,
        sale_price_amount: 1200,
        delivery_fee_cents: 100,
        restock_fee_cents: 2000,
        reduced_price_cents: 1500,
        reduced_price_currency: :lvl,
        lambda_price_cents: 4000
      )
    end

    describe "#write_monetized" do
      let(:value) { Money.new(1_000, "LVL") }

      it "sets monetized attribute's value to Money object" do
        product.write_monetized :price, :price_cents, value, false, nil, {}

        expect(product.price).to be_an_instance_of(Money)
        expect(product.price_cents).to eq(value.cents)
        # Because :price does not have a column for currency
        expect(product.price.currency).to eq(Product.currency)
      end

      it "sets monetized attribute's value from a given Fixnum" do
        product.write_monetized :price, :price_cents, 10, false, nil, {}

        expect(product.price).to be_an_instance_of(Money)
        expect(product.price_cents).to eq(1000)
      end

      it "sets monetized attribute's value from a given Float" do
        product.write_monetized :price, :price_cents, 10.5, false, nil, {}

        expect(product.price).to be_an_instance_of(Money)
        expect(product.price_cents).to eq(1050)
      end

      it "resets monetized attribute when given blank input" do
        product.write_monetized :price, :price_cents, nil, false, nil, { allow_nil: true }

        expect(product.price).to be_nil
      end

      it "sets monetized attribute to 0 when given a blank value" do
        currency = product.price.currency
        product.write_monetized :price, :price_cents, nil, false, nil, {}

        expect(product.price.amount).to eq(0)
        expect(product.price.currency).to eq(currency)
      end

      it "does not memoize monetized attribute's value if currency is read-only" do
        product.write_monetized :price, :price_cents, value, false, nil, {}

        price = product.instance_variable_get(:@price)

        expect(price).to be_an_instance_of(Money)
        expect(price.amount).not_to eq(value.amount)
      end

      context "without a default currency" do
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
          end.to raise_error(Money::Currency::NoCurrency, "must provide a currency")
        end
      end

      describe "instance_currency_name" do
        it "updates instance_currency_name attribute" do
          product.write_monetized :sale_price, :sale_price_amount, value, false, :sale_price_currency_code, {}

          expect(product.sale_price).to eq(value)
          expect(product.sale_price_currency_code).to eq("LVL")
        end

        it "memoizes monetized attribute's value with currency" do
          product.write_monetized :sale_price, :sale_price_amount, value, false, :sale_price_currency_code, {}

          expect(product.instance_variable_get(:@sale_price)).to eq(value)
        end

        it "ignores empty instance_currency_name" do
          product.write_monetized :sale_price, :sale_price_amount, value, false, "", {}

          expect(product.sale_price.amount).to eq(value.amount)
          expect(product.sale_price.currency).to eq(Product.currency)
        end

        it "ignores instance_currency_name that model does not respond to" do
          product.write_monetized :sale_price, :sale_price_amount, value, false, :non_existing_currency, {}

          expect(product.sale_price.amount).to eq(value.amount)
          expect(product.sale_price.currency).to eq(Product.currency)
        end
      end
    end
  end
end
