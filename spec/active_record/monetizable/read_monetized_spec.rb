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

    describe "#read_monetized" do
      it "returns monetized attribute's value" do
        reduced_price = product.read_monetized(:reduced_price, :reduced_price_cents)

        expect(reduced_price).to be_an_instance_of(Money)
        expect(reduced_price).to eq(Money.new(product.reduced_price_cents, product.reduced_price_currency))
      end

      context "when memoized" do
        it "memoizes monetized attribute's value" do
          product.instance_variable_set :@reduced_price, nil
          reduced_price = product.read_monetized(:reduced_price, :reduced_price_cents)

          expect(product.instance_variable_get(:@reduced_price)).to eq(reduced_price)
        end

        it "resets memoized attribute's value if amount has changed" do
          reduced_price = product.read_monetized(:reduced_price, :reduced_price_cents)
          product.reduced_price_cents = 100

          expect(product.read_monetized(:reduced_price, :reduced_price_cents)).not_to eq(reduced_price)
        end

        it "resets memoized attribute's value if currency has changed" do
          reduced_price = product.read_monetized(:reduced_price, :reduced_price_cents)
          product.reduced_price_currency = "CAD"

          expect(product.read_monetized(:reduced_price, :reduced_price_cents)).not_to eq(reduced_price)
        end
      end

      context "with preserve_user_input set" do
        around do |example|
          MoneyRails::Configuration.preserve_user_input = true
          example.run
          MoneyRails::Configuration.preserve_user_input = false
        end

        it "has no effect if validation passes" do
          product.price = "14"

          expect(product.save).to be_truthy
          expect(product.read_monetized(:price, :price_cents).to_s).to eq("14.00")
        end

        it "preserves user input if validation fails" do
          product.price = "14,0"

          expect(product.save).to be_falsy
          expect(product.read_monetized(:price, :price_cents).to_s).to eq("14,0")
        end
      end

      context "with a monetized attribute that is nil" do
        let(:service) do
          Service.create(discount_cents: nil)
        end

        # rubocop:disable RSpec/VerifiedDoubles
        let(:default_currency_lambda) do
          double :default_fallback, read_currency: nil
        end
        # rubocop:enable RSpec/VerifiedDoubles

        let(:read_monetized) { service.read_monetized(:discount, :discount_cents, options) }

        around do |example|
          service # Instantiate instance which relies on Money.default_currency
          original_default_currency = Money.default_currency
          Money.default_currency = -> { default_currency_lambda.read_currency }
          example.run
          Money.default_currency = original_default_currency
        end

        context "when allow_nil options is set" do
          let(:options) { { allow_nil: true } }

          before do
            allow(default_currency_lambda).to receive(:read_currency)
          end

          it "does not attempt to read the fallback default currency" do
            read_monetized

            expect(default_currency_lambda).not_to have_received(:read_currency)
          end
        end
      end
    end
  end
end
