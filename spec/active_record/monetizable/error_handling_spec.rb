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

    describe "error handling" do
      let!(:old_price_value) { product.price }

      it "ignores values that do not implement to_money method" do
        product.write_monetized :price, :price_cents, [10], false, nil, {}

        expect(product.price).to eq(old_price_value)
      end

      context "with raise_error_on_money_parsing enabled" do
        before { MoneyRails.raise_error_on_money_parsing = true }
        after { MoneyRails.raise_error_on_money_parsing = false }

        it "raises a MoneyRails::Error when given an invalid value" do
          expect do
            product.write_monetized :price, :price_cents, "10-50", false, nil, {}
          end.to raise_error(MoneyRails::Error)
        end

        it "raises a MoneyRails::Error error when trying to set invalid currency" do
          allow(product).to receive(:currency_for_price).and_return("INVALID_CURRENCY")
          expect do
            product.write_monetized :price, :price_cents, 10, false, nil, {}
          end.to raise_error(MoneyRails::Error)
        end
      end

      context "with raise_error_on_money_parsing disabled" do
        it "ignores when given invalid value" do
          product.write_monetized :price, :price_cents, "10-50", false, nil, {}

          expect(product.price).to eq(old_price_value)
        end

        it "raises a MoneyRails::Error error when trying to set invalid currency" do
          allow(product).to receive(:currency_for_price).and_return("INVALID_CURRENCY")
          product.write_monetized :price, :price_cents, 10, false, nil, {}

          # Can not use public accessor here because currency_for_price is stubbed
          expect(product.instance_variable_get(:@price)).to eq(old_price_value)
        end
      end
    end
  end
end
