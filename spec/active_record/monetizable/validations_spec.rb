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
        lambda_price_cents: 4000,
      )
    end

    describe ".monetize" do
      let(:service) do
        Service.create(charge_cents: 2000, discount_cents: 120)
      end

      it "uses numericality validation" do
        product.price_cents = "foo"
        expect(product.save).to be_falsey

        product.price_cents = 2000
        expect(product.save).to be_truthy
      end

      it "skips numericality validation when disabled" do
        product.accessor_price_cents = "not_valid"
        expect(product.save).to be_truthy
      end

      it "passes validation after updating fractional attribute which was previously invalid" do
        product.price_in_a_range = -5
        expect(product).not_to be_valid
        product.price_in_a_range_cents = 500
        expect(product).to be_valid
      end

      context "when MoneyRails.raise_error_on_money_parsing is true" do
        before { MoneyRails.raise_error_on_money_parsing = true }
        after { MoneyRails.raise_error_on_money_parsing = false }

        it "raises exception when a String value with hyphen is assigned" do
          expect { product.accessor_price = "10-235" }.to raise_error MoneyRails::Error
        end

        it "raises an exception if it can't change currency" do
          expect do
            Product.new.price = Money.new(10, "RUB")
          end.to raise_error(
            MoneyRails::ActiveRecord::Monetizable::ReadOnlyCurrencyException,
            "Can't change readonly currency 'USD' to 'RUB' for field 'price'",
          )
        end
      end

      context "when MoneyRails.raise_error_on_money_parsing is false (default)" do
        it "does not raise exception when a String value with hyphen is assigned" do
          expect { product.accessor_price = "10-235" }.not_to raise_error
        end

        it "does not raise exception if it can't change currency" do
          expect { Product.new.price = Money.new(10, "RUB") }.not_to raise_error
        end
      end

      it "respects numericality validation when using update" do
        expect(product.update(price_cents: "some text")).to be_falsey
        expect(product.update(price_cents: 2000)).to be_truthy
      end

      it "uses numericality validation on money attribute" do
        product.price = "some text"
        expect(product.save).to be_falsey

        product.price = Money.new(320, "USD")
        expect(product.save).to be_truthy

        product.sale_price = "12.34"
        product.sale_price_currency_code = "EUR"
        expect(product.valid?).to be_truthy
      end

      it "separately skips price validations" do
        product.skip_validation_price = "hundred thousands"
        expect(product.save).to be_truthy
      end

      it "separately skips subunit validations" do
        product.skip_validation_price_cents = "ten million"
        expect(product.save).to be_truthy
      end

      it "does not init empty key in errors" do
        product.price = Money.new(320, "USD")
        product.valid?
        expect(product.errors.key?(:price)).to be_falsey
      end

      it "fails validation with the proper error message if money value is invalid decimal" do
        product.price = "12.23.24"
        expect(product.save).to be_falsey
        expect(product.errors[:price].size).to eq(1)
        expect(product.errors[:price].first).to include("not a number")
      end

      it "fails validation with the proper error message if money value is nothing but periods" do
        product.price = "..."
        expect(product.save).to be_falsey
        expect(product.errors[:price].size).to eq(1)
        expect(product.errors[:price].first).to include("not a number")
      end

      it "fails validation with the proper error message if money value has invalid thousands part" do
        product.price = "12,23.24"
        expect(product.save).to be_falsey
        expect(product.errors[:price].size).to eq(1)
        expect(product.errors[:price].first).to include("has invalid format")
        expect(product.errors[:price].first).to match(/Got 12,23.24/)
      end

      it "fails validation with the proper error message if money value has thousand char after decimal mark" do
        product.price = "1.234,56"
        expect(product.save).to be_falsey
        expect(product.errors[:price].size).to eq(1)
        expect(product.errors[:price].first).to include("has invalid format")
        expect(product.errors[:price].first).to match(/Got 1.234,56/)
      end

      it "allows an empty string as the thousands separator" do
        I18n.locale = "en-US"
        product.price = "10.00"
        expect(product).to be_valid
      ensure
        I18n.locale = I18n.default_locale
      end

      it "passes validation if money value is a Float and the currency decimal mark is not period" do
        # The corresponding String would be "12,34" euros
        service.discount = 12.34
        expect(service.save).to be_truthy
      end

      it "passes validation if money value is a Float" do
        product.price = 12.34
        expect(product.save).to be_truthy
      end

      it "passes validation if money value is an Integer" do
        product.price = 12
        expect(product.save).to be_truthy
      end

      it "fails validation with the proper error message using numericality validations" do
        product.price_in_a_range = "-12"
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range].size).to eq(1)
        expect(product.errors[:price_in_a_range].first).to include("must be greater than zero and less than $100")

        product.price_in_a_range = Money.new(-1200, "USD")
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range].size).to eq(1)
        expect(product.errors[:price_in_a_range].first).to include("must be greater than zero and less than $100")

        product.price_in_a_range = "0"
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range].size).to eq(1)
        expect(product.errors[:price_in_a_range].first).to include("must be greater than zero and less than $100")

        product.price_in_a_range = "12"
        expect(product.valid?).to be_truthy

        product.price_in_a_range = Money.new(1200, "USD")
        expect(product.valid?).to be_truthy

        product.price_in_a_range = "101"
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range].size).to eq(1)
        expect(product.errors[:price_in_a_range].first).to include("must be greater than zero and less than $100")

        product.price_in_a_range = Money.new(10100, "USD")
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range].size).to eq(1)
        expect(product.errors[:price_in_a_range].first).to include("must be greater than zero and less than $100")
      end

      it "fails validation if linked attribute changed" do
        product = Product.create(price: Money.new(3210, "USD"), discount: 150,
                                 validates_method_amount: 100,
                                 bonus_cents: 200, optional_price: 100)
        expect(product.valid?).to be_truthy
        product.optional_price = 50
        expect(product.valid?).to be_falsey
      end

      it "fails validation with the proper error message using validates :money" do
        product.validates_method_amount = "-12"
        expect(product.valid?).to be_falsey
        expect(product.errors[:validates_method_amount].size).to eq(1)
        expect(product.errors[:validates_method_amount].first).to include("must be greater than zero and less than $100")

        product.validates_method_amount = Money.new(-1200, "USD")
        expect(product.valid?).to be_falsey
        expect(product.errors[:validates_method_amount].size).to eq(1)
        expect(product.errors[:validates_method_amount].first).to include("must be greater than zero and less than $100")

        product.validates_method_amount = "0"
        expect(product.valid?).to be_falsey
        expect(product.errors[:validates_method_amount].size).to eq(1)
        expect(product.errors[:validates_method_amount].first).to include("must be greater than zero and less than $100")

        product.validates_method_amount = "12"
        expect(product.valid?).to be_truthy

        product.validates_method_amount = Money.new(1200, "USD")
        expect(product.valid?).to be_truthy

        product.validates_method_amount = "101"
        expect(product.valid?).to be_falsey
        expect(product.errors[:validates_method_amount].size).to eq(1)
        expect(product.errors[:validates_method_amount].first).to include("must be greater than zero and less than $100")

        product.validates_method_amount = Money.new(10100, "USD")
        expect(product.valid?).to be_falsey
        expect(product.errors[:validates_method_amount].size).to eq(1)
        expect(product.errors[:validates_method_amount].first).to include("must be greater than zero and less than $100")
      end

      it "fails validation with the proper error message on the cents field" do
        product.price_in_a_range = "-12"
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range_cents].size).to eq(1)
        expect(product.errors[:price_in_a_range_cents].first).to include("greater than 0")

        product.price_in_a_range = "0"
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range_cents].size).to eq(1)
        expect(product.errors[:price_in_a_range_cents].first).to include("greater than 0")

        product.price_in_a_range = "12"
        expect(product.valid?).to be_truthy

        product.price_in_a_range = "101"
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range_cents].size).to eq(1)
        expect(product.errors[:price_in_a_range_cents].first).to include("less than or equal to 10000")
      end

      it "fails validation when a non number string is given" do
        product = Product.create(price_in_a_range: "asd")
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range].size).to eq(1)
        expect(product.errors[:price_in_a_range].first).to include("greater than zero")

        product = Product.create(price_in_a_range: "asd23")
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range].size).to eq(1)
        expect(product.errors[:price_in_a_range].first).to include("greater than zero")

        product = Product.create(price: "asd")
        expect(product.valid?).to be_falsey
        expect(product.errors[:price].size).to eq(1)
        expect(product.errors[:price].first).to include("is not a number")

        product = Product.create(price: "asd23")
        expect(product.valid?).to be_falsey
        expect(product.errors[:price].size).to eq(1)
        expect(product.errors[:price].first).to include("is not a number")
      end

      it "passes validation when amount contains spaces (999 999.99)" do
        product.price = "999 999.99"
        expect(product).to be_valid
        expect(product.price_cents).to eq(99999999)
      end

      it "passes validation when amount contains underscores (999_999.99)" do
        product.price = "999_999.99"
        expect(product).to be_valid
        expect(product.price_cents).to eq(99999999)
      end

      it "passes validation if money value has correct format" do
        product.price = "12,230.24"
        expect(product.save).to be_truthy
      end

      it "passes validation if there is a whitespace between the currency symbol and amount" do
        product.price = "$ 123,456.78"
        expect(product.save).to be_truthy
      end

      it "respects numericality validation when using update on money attribute" do
        expect(product.update(price: "some text")).to be_falsey
        expect(product.update(price: Money.new(320, "USD"))).to be_truthy
      end

      it "uses i18n currency format when validating" do
        old_locale = I18n.locale

        I18n.locale = "en-GB"
        Money.default_currency = Money::Currency.find("EUR")
        expect("12.00".to_money).to eq(Money.new(1200, :eur))
        transaction = Transaction.new(amount: "12.00", tax: "13.00")
        expect(transaction.amount_cents).to eq(1200)
        expect(transaction.valid?).to be_truthy

        # reset locale setting
        I18n.locale = old_locale
      end
    end
  end
end
