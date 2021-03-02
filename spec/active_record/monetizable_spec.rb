# encoding: utf-8

require 'spec_helper'

class Sub < Product; end

if defined? ActiveRecord
  describe MoneyRails::ActiveRecord::Monetizable do
    let(:product) do
      Product.create(price_cents: 3000, discount: 150,
                     bonus_cents: 200, optional_price: 100,
                     sale_price_amount: 1200, delivery_fee_cents: 100,
                     restock_fee_cents: 2000,
                     reduced_price_cents: 1500, reduced_price_currency: :lvl,
                     lambda_price_cents: 4000)
    end

    describe ".monetize" do
      let(:service) do
        Service.create(charge_cents: 2000, discount_cents: 120)
      end

      def update_product(*attributes)
        if defined?(::ActiveRecord::VERSION) && ::ActiveRecord::VERSION::MAJOR >= 5
          product.update(*attributes)
        else
          product.update_attributes(*attributes)
        end
      end

      context ".monetized_attributes" do

        class InheritedMonetizeProduct < Product
          monetize :special_price_cents
        end

        it "should be inherited by subclasses" do
          assert_monetized_attributes(Sub.monetized_attributes, Product.monetized_attributes)
        end

        it "should be inherited by subclasses with new monetized attribute" do
          assert_monetized_attributes(InheritedMonetizeProduct.monetized_attributes, Product.monetized_attributes.merge(special_price: "special_price_cents"))
        end

        def assert_monetized_attributes(monetized_attributes, expected_attributes)
          expect(monetized_attributes).to include expected_attributes
          expect(expected_attributes).to include monetized_attributes
          expect(monetized_attributes.size).to eql expected_attributes.size
          monetized_attributes.keys.each do |key|
            expect(key.is_a? String).to be_truthy
          end
        end
      end

      it "attaches a Money object to model field" do
        expect(product.price).to be_an_instance_of(Money)
        expect(product.discount_value).to be_an_instance_of(Money)
        expect(product.bonus).to be_an_instance_of(Money)
      end

      it "attaches Money objects to multiple model fields" do
        expect(product.delivery_fee).to be_an_instance_of(Money)
        expect(product.restock_fee).to be_an_instance_of(Money)
      end

      it "returns the expected money amount as a Money object" do
        expect(product.price).to eq(Money.new(3000, "USD"))
      end

      it "assigns the correct value from a Money object" do
        product.price = Money.new(3210, "USD")
        expect(product.save).to be_truthy
        expect(product.price_cents).to eq(3210)
      end

      it "assigns the correct value from a Money object using create" do
        product = Product.create(price: Money.new(3210, "USD"), discount: 150,
                                 bonus_cents: 200, optional_price: 100)
        expect(product.valid?).to be_truthy
        expect(product.price_cents).to eq(3210)
      end

      it "correctly updates from a Money object using update_attributes" do
        expect(update_product(price: Money.new(215, "USD"))).to be_truthy
        expect(product.price_cents).to eq(215)
      end

      it "assigns the correct value from params" do
        params_clp = { amount: '20000', tax: '1000', currency: 'CLP' }
        product = Transaction.create(params_clp)
        expect(product.valid?).to be_truthy
        expect(product.amount.currency.subunit_to_unit).to eq(1)
        expect(product.amount_cents).to eq(20000)
      end

      # TODO: This is a slightly controversial example, btu it reflects the current behaviour
      it "re-assigns cents amount when subunit/unit ratio changes preserving amount in units" do
        transaction = Transaction.create(amount: '20000', tax: '1000', currency: 'USD')

        expect(transaction.amount).to eq(Money.new(20000_00, 'USD'))

        transaction.currency = 'CLP'

        expect(transaction.amount).to eq(Money.new(20000, 'CLP'))
        expect(transaction.amount_cents).to eq(20000)
      end

      it "raises an error if trying to create two attributes with the same name" do
        expect do
          class Product
            monetize :discount, as: :price
          end
        end.to raise_error ArgumentError
      end

      it "raises an error if Money object has the same attribute name as the monetizable attribute" do
        expect do
          class AnotherProduct < Product
            monetize :price_cents, as: :price_cents
          end
        end.to raise_error ArgumentError
      end

      it "raises an error when unable to infer attribute name" do
        old_postfix = MoneyRails::Configuration.amount_column[:postfix]
        MoneyRails::Configuration.amount_column[:postfix] = '_pennies'

        expect do
          class AnotherProduct < Product
            monetize :price_cents
          end
        end.to raise_error ArgumentError

        MoneyRails::Configuration.amount_column[:postfix] = old_postfix
      end

      it "allows subclass to redefine attribute with the same name" do
        class SubProduct < Product
          monetize :discount, as: :discount_price, with_currency: :gbp
        end

        sub_product = SubProduct.new(discount: 100)

        expect(sub_product.discount_price).to be_an_instance_of(Money)
        expect(sub_product.discount_price.currency.id).to equal :gbp
      end

      it "respects :as argument" do
        expect(product.discount_value).to eq(Money.new(150, "USD"))
      end

      it "uses numericality validation" do
        product.price_cents = "foo"
        expect(product.save).to be_falsey

        product.price_cents = 2000
        expect(product.save).to be_truthy
      end

      it "skips numericality validation when disabled" do
        product.accessor_price_cents = 'not_valid'
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
          expect {
            Product.new.price = Money.new(10, "RUB")
          }.to raise_error(MoneyRails::ActiveRecord::Monetizable::ReadOnlyCurrencyException, "Can't change readonly currency 'USD' to 'RUB' for field 'price'")
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

      it "respects numericality validation when using update_attributes" do
        expect(update_product(price_cents: "some text")).to be_falsey
        expect(update_product(price_cents: 2000)).to be_truthy
      end

      it "uses numericality validation on money attribute" do
        product.price = "some text"
        expect(product.save).to be_falsey

        product.price = Money.new(320, "USD")
        expect(product.save).to be_truthy

        product.sale_price = "12.34"
        product.sale_price_currency_code = 'EUR'
        expect(product.valid?).to be_truthy
      end

      it "separately skips price validations" do
        product.skip_validation_price = 'hundred thousands'
        expect(product.save).to be_truthy
      end

      it "separately skips subunit validations" do
        product.skip_validation_price_cents = 'ten million'
        expect(product.save).to be_truthy
      end

      it "shouldn't init empty key in errors" do
        product.price = Money.new(320, "USD")
        product.valid?
        expect(product.errors.has_key?(:price)).to be_falsey
      end

      it "fails validation with the proper error message if money value is invalid decimal" do
        product.price = "12.23.24"
        expect(product.save).to be_falsey
        expect(product.errors[:price].size).to eq(1)
        expect(product.errors[:price].first).to match(/not a number/)
      end

      it "fails validation with the proper error message if money value is nothing but periods" do
        product.price = "..."
        expect(product.save).to be_falsey
        expect(product.errors[:price].size).to eq(1)
        expect(product.errors[:price].first).to match(/not a number/)
      end

      it "fails validation with the proper error message if money value has invalid thousands part" do
        product.price = "12,23.24"
        expect(product.save).to be_falsey
        expect(product.errors[:price].size).to eq(1)
        expect(product.errors[:price].first).to match(/must be a valid/)
        expect(product.errors[:price].first).to match(/Got 12,23.24/)
      end

      it "fails validation with the proper error message if money value has thousand char after decimal mark" do
        product.price = "1.234,56"
        expect(product.save).to be_falsey
        expect(product.errors[:price].size).to eq(1)
        expect(product.errors[:price].first).to match(/must be a valid/)
        expect(product.errors[:price].first).to match(/Got 1.234,56/)
      end

      it "allows an empty string as the thousands separator" do
        begin
          I18n.locale = 'en-US'
          product.price = '10.00'
          expect(product).to be_valid
        ensure
          I18n.locale = I18n.default_locale
        end
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
        expect(product.errors[:price_in_a_range].first).to match(/must be greater than zero and less than \$100/)

        product.price_in_a_range = Money.new(-1200, "USD")
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range].size).to eq(1)
        expect(product.errors[:price_in_a_range].first).to match(/must be greater than zero and less than \$100/)

        product.price_in_a_range = "0"
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range].size).to eq(1)
        expect(product.errors[:price_in_a_range].first).to match(/must be greater than zero and less than \$100/)

        product.price_in_a_range = "12"
        expect(product.valid?).to be_truthy

        product.price_in_a_range = Money.new(1200, "USD")
        expect(product.valid?).to be_truthy

        product.price_in_a_range = "101"
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range].size).to eq(1)
        expect(product.errors[:price_in_a_range].first).to match(/must be greater than zero and less than \$100/)

        product.price_in_a_range = Money.new(10100, "USD")
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range].size).to eq(1)
        expect(product.errors[:price_in_a_range].first).to match(/must be greater than zero and less than \$100/)
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
        expect(product.errors[:validates_method_amount].first).to match(/must be greater than zero and less than \$100/)

        product.validates_method_amount = Money.new(-1200, "USD")
        expect(product.valid?).to be_falsey
        expect(product.errors[:validates_method_amount].size).to eq(1)
        expect(product.errors[:validates_method_amount].first).to match(/must be greater than zero and less than \$100/)

        product.validates_method_amount = "0"
        expect(product.valid?).to be_falsey
        expect(product.errors[:validates_method_amount].size).to eq(1)
        expect(product.errors[:validates_method_amount].first).to match(/must be greater than zero and less than \$100/)

        product.validates_method_amount = "12"
        expect(product.valid?).to be_truthy

        product.validates_method_amount = Money.new(1200, "USD")
        expect(product.valid?).to be_truthy

        product.validates_method_amount = "101"
        expect(product.valid?).to be_falsey
        expect(product.errors[:validates_method_amount].size).to eq(1)
        expect(product.errors[:validates_method_amount].first).to match(/must be greater than zero and less than \$100/)

        product.validates_method_amount = Money.new(10100, "USD")
        expect(product.valid?).to be_falsey
        expect(product.errors[:validates_method_amount].size).to eq(1)
        expect(product.errors[:validates_method_amount].first).to match(/must be greater than zero and less than \$100/)
      end

      it "fails validation with the proper error message on the cents field " do
        product.price_in_a_range = "-12"
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range_cents].size).to eq(1)
        expect(product.errors[:price_in_a_range_cents].first).to match(/greater than 0/)

        product.price_in_a_range = "0"
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range_cents].size).to eq(1)
        expect(product.errors[:price_in_a_range_cents].first).to match(/greater than 0/)

        product.price_in_a_range = "12"
        expect(product.valid?).to be_truthy

        product.price_in_a_range = "101"
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range_cents].size).to eq(1)
        expect(product.errors[:price_in_a_range_cents].first).to match(/less than or equal to 10000/)
      end

      it "fails validation when a non number string is given" do
        product = Product.create(price_in_a_range: "asd")
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range].size).to eq(1)
        expect(product.errors[:price_in_a_range].first).to match(/greater than zero/)

        product = Product.create(price_in_a_range: "asd23")
        expect(product.valid?).to be_falsey
        expect(product.errors[:price_in_a_range].size).to eq(1)
        expect(product.errors[:price_in_a_range].first).to match(/greater than zero/)

        product = Product.create(price: "asd")
        expect(product.valid?).to be_falsey
        expect(product.errors[:price].size).to eq(1)
        expect(product.errors[:price].first).to match(/is not a number/)

        product = Product.create(price: "asd23")
        expect(product.valid?).to be_falsey
        expect(product.errors[:price].size).to eq(1)
        expect(product.errors[:price].first).to match(/is not a number/)
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

      it "respects numericality validation when using update_attributes on money attribute" do
        expect(update_product(price: "some text")).to be_falsey
        expect(update_product(price: Money.new(320, 'USD'))).to be_truthy
      end

      it "uses i18n currency format when validating" do
        old_locale = I18n.locale

        I18n.locale = "en-GB"
        Money.default_currency = Money::Currency.find('EUR')
        expect("12.00".to_money).to eq(Money.new(1200, :eur))
        transaction = Transaction.new(amount: "12.00", tax: "13.00")
        expect(transaction.amount_cents).to eq(1200)
        expect(transaction.valid?).to be_truthy

        # reset locale setting
        I18n.locale = old_locale
      end

      it "doesn't allow nil by default" do
        product.price_cents = nil
        expect(product.save).to be_falsey
      end

      it "allows nil if optioned" do
        product.optional_price = nil
        expect(product.save).to be_truthy
        expect(product.optional_price).to be_nil
      end

      it "doesn't raise exception if validation is used and nil is not allowed" do
        expect { product.price = nil }.to_not raise_error
      end

      it "doesn't save nil values if validation is used and nil is not allowed" do
        product.price = nil
        product.save
        expect(product.price_cents).not_to be_nil
      end

      it "resets money_before_type_cast attr every time a save operation occurs" do
        v = Money.new(100, :usd)
        product.price = v
        expect(product.price_money_before_type_cast).to eq(v)
        product.save
        expect(product.price_money_before_type_cast).to be_nil
        product.price = 10
        expect(product.price_money_before_type_cast).to eq(10)
        product.save
        expect(product.price_money_before_type_cast).to be_nil
      end

      it "does not reset money_before_type_cast attr if save operation fails" do
        product.bonus = ""
        expect(product.bonus_money_before_type_cast).to eq("")
        expect(product.save).to be_falsey
        expect(product.bonus_money_before_type_cast).to eq("")
      end

      it "uses Money default currency if :with_currency has not been used" do
        expect(service.discount.currency).to eq(Money::Currency.find(:eur))
      end

      it "overrides default currency with the currency registered for the model" do
        expect(product.price.currency).to eq(Money::Currency.find(:usd))
      end

      it "overrides default currency with the value of :with_currency argument" do
        expect(service.charge.currency).to eq(Money::Currency.find(:usd))
        expect(product.bonus.currency).to eq(Money::Currency.find(:gbp))
      end

      it "uses currency postfix to determine attribute that stores currency" do
        expect(product.reduced_price.currency).to eq(Money::Currency.find(:lvl))
      end

      it "correctly assigns Money objects to the attribute" do
        product.price = Money.new(2500, :USD)
        expect(product.save).to be_truthy
        expect(product.price.cents).to eq(2500)
        expect(product.price.currency.to_s).to eq("USD")
      end

      it "correctly assigns Fixnum objects to the attribute" do
        product.price = 25
        expect(product.save).to be_truthy
        expect(product.price.cents).to eq(2500)
        expect(product.price.currency.to_s).to eq("USD")

        service.discount = 2
        expect(service.save).to be_truthy
        expect(service.discount.cents).to eq(200)
        expect(service.discount.currency.to_s).to eq("EUR")
      end

      it "correctly assigns String objects to the attribute" do
        product.price = "25"
        expect(product.save).to be_truthy
        expect(product.price.cents).to eq(2500)
        expect(product.price.currency.to_s).to eq("USD")

        service.discount = "2"
        expect(service.save).to be_truthy
        expect(service.discount.cents).to eq(200)
        expect(service.discount.currency.to_s).to eq("EUR")
      end

      it "correctly assigns objects to a accessor attribute" do
        product.accessor_price = 1.23
        expect(product.save).to be_truthy
        expect(product.accessor_price.cents).to eq(123)
        expect(product.accessor_price_cents).to eq(123)
      end

      it "overrides default, model currency with the value of :with_currency in fixnum assignments" do
        product.bonus = 25
        expect(product.save).to be_truthy
        expect(product.bonus.cents).to eq(2500)
        expect(product.bonus.currency.to_s).to eq("GBP")

        service.charge = 2
        expect(service.save).to be_truthy
        expect(service.charge.cents).to eq(200)
        expect(service.charge.currency.to_s).to eq("USD")
      end

      it "overrides default, model currency with the value of :with_currency in string assignments" do
        product.bonus = "25"
        expect(product.save).to be_truthy
        expect(product.bonus.cents).to eq(2500)
        expect(product.bonus.currency.to_s).to eq("GBP")

        service.charge = "2"
        expect(service.save).to be_truthy
        expect(service.charge.cents).to eq(200)
        expect(service.charge.currency.to_s).to eq("USD")

        product.lambda_price = "32"
        expect(product.save).to be_truthy
        expect(product.lambda_price.cents).to eq(3200)
        expect(product.lambda_price.currency.to_s).to eq("CAD")
      end

      it "overrides default currency with model currency, in fixnum assignments" do
        product.discount_value = 5
        expect(product.save).to be_truthy
        expect(product.discount_value.cents).to eq(500)
        expect(product.discount_value.currency.to_s).to eq("USD")
      end

      it "overrides default currency with model currency, in string assignments" do
        product.discount_value = "5"
        expect(product.save).to be_truthy
        expect(product.discount_value.cents).to eq(500)
        expect(product.discount_value.currency.to_s).to eq("USD")
      end

      it "falls back to default currency, in fixnum assignments" do
        service.discount = 5
        expect(service.save).to be_truthy
        expect(service.discount.cents).to eq(500)
        expect(service.discount.currency.to_s).to eq("EUR")
      end

      it "falls back to default currency, in string assignments" do
        service.discount = "5"
        expect(service.save).to be_truthy
        expect(service.discount.cents).to eq(500)
        expect(service.discount.currency.to_s).to eq("EUR")
      end

      it "sets field to nil, in nil assignments if allow_nil is set" do
        product.optional_price = nil
        expect(product.save).to be_truthy
        expect(product.optional_price).to be_nil
      end

      it "sets field to nil, in instantiation if allow_nil is set" do
        pr = Product.new(optional_price: nil, price_cents: 5320,
                         discount: 350, bonus_cents: 320)
        expect(pr.optional_price).to be_nil
        expect(pr.save).to be_truthy
        expect(pr.optional_price).to be_nil
      end

      it "sets field to nil, in blank assignments if allow_nil is set" do
        product.optional_price = ""
        expect(product.save).to be_truthy
        expect(product.optional_price).to be_nil
      end

      context "when the monetized field is an aliased attribute" do
        it "writes the subunits to the original (unaliased) column" do
          pending if Rails::VERSION::MAJOR < 4
          product.renamed = "$10.00"
          expect(product.aliased_cents).to eq 10_00
        end
      end

      context "for column with model currency:" do
        it "has default currency if not specified" do
          product = Product.create(sale_price_amount: 1234)
          product.sale_price.currency.to_s == 'USD'
        end

        it "is overridden by instance currency column" do
          product = Product.create(sale_price_amount: 1234,
                                   sale_price_currency_code: 'CAD')
          expect(product.sale_price.currency.to_s).to eq('CAD')
        end

        it 'can change currency of custom column' do
          product = Product.create!(
            price: Money.new(10,'USD'),
            bonus: Money.new(10,'GBP'),
            discount: 10,
            sale_price_amount: 1234,
            sale_price_currency_code: 'USD'
          )

          expect(product.sale_price.currency.to_s).to eq('USD')

          product.sale_price = Money.new 456, 'CAD'
          product.save
          product.reload

          expect(product.sale_price.currency.to_s).to eq('CAD')
          expect(product.discount_value.currency.to_s).to eq('USD')
        end
      end

      context "for model with currency column:" do
        let(:transaction) do
          Transaction.create(amount_cents: 2400, tax_cents: 600,
                             currency: :usd)
        end

        let(:dummy_product) do
          DummyProduct.create(price_cents: 2400, currency: :usd)
        end

        let(:dummy_product_with_nil_currency) do
          DummyProduct.create(price_cents: 2600) # nil currency
        end

        let(:dummy_product_with_invalid_currency) do
          # invalid currency
          DummyProduct.create(price_cents: 2600, currency: :foo)
        end

        it "correctly serializes the currency to a new instance of model" do
          d = DummyProduct.new
          d.price = Money.new(10, "EUR")
          d.save!
          d.reload
          expect(d.currency).to eq("EUR")
        end

        it "overrides default currency with the value of row currency" do
          expect(transaction.amount.currency).to eq(Money::Currency.find(:usd))
        end

        it "overrides default currency with the currency registered for the model" do
          expect(dummy_product_with_nil_currency.price.currency).to eq(
            Money::Currency.find(:gbp)
          )
        end

        it "overrides default currency with the currency registered for the model if currency is invalid" do
          expect(dummy_product_with_invalid_currency.price.currency).to eq(
            Money::Currency.find(:gbp)
          )
        end

        it "overrides default and model currency with the row currency" do
          expect(dummy_product.price.currency).to eq(Money::Currency.find(:usd))
        end

        it "constructs the money attribute from the stored mapped attribute values" do
          expect(transaction.amount).to eq(Money.new(2400, :usd))
        end

        it "correctly instantiates Money objects from the mapped attributes" do
          t = Transaction.new(amount_cents: 2500, currency: "CAD")
          expect(t.amount).to eq(Money.new(2500, "CAD"))
        end

        it "correctly assigns Money objects to the attribute" do
          transaction.amount = Money.new(2500, :eur)
          expect(transaction.save).to be_truthy
          expect(transaction.amount.cents).to eq(Money.new(2500, :eur).cents)
          expect(transaction.amount.currency.to_s).to eq("EUR")
        end

        it "uses default currency if a non Money object is assigned to the attribute" do
          transaction.amount = 234
          expect(transaction.amount.currency.to_s).to eq("USD")
        end

        it "constructs the money object from the mapped method value" do
          expect(transaction.total).to eq(Money.new(3000, :usd))
        end

        it "allows currency column postfix to be blank" do
          allow(MoneyRails::Configuration).to receive(:currency_column) { { postfix: nil, column_name: 'currency' } }
          expect(dummy_product_with_nil_currency.price.currency).to eq(Money::Currency.find(:gbp))
        end

        it "updates inferred currency column based on currency column postfix" do
          product.reduced_price = Money.new(999_00, 'CAD')
          product.save

          expect(product.reduced_price_cents).to eq(999_00)
          expect(product.reduced_price_currency).to eq('CAD')
        end

        context "and field with allow_nil: true" do
          it "doesn't set currency to nil when setting the field to nil" do
            t = Transaction.new(amount_cents: 2500, currency: "CAD")
            t.optional_amount = nil
            expect(t.currency).to eq("CAD")
          end
        end

        # TODO: these specs should mock locale_backend with expected values
        #       instead of manipulating it directly
        context "and an Italian locale" do
          around(:each) do |example|
            I18n.with_locale(:it) do
              example.run
            end
          end

          context "when using :i18n locale backend" do
            it "validates with the locale's decimal mark" do
              transaction.amount = "123,45"
              expect(transaction.valid?).to be_truthy
            end

            it "does not validate with the currency's decimal mark" do
              transaction.amount = "123.45"
              expect(transaction.valid?).to be_falsey
            end

            it "validates with the locale's currency symbol" do
              transaction.amount = "€123"
              expect(transaction.valid?).to be_truthy
            end

            it "does not validate with the transaction's currency symbol" do
              transaction.amount = "$123.45"
              expect(transaction.valid?).to be_falsey
            end
          end

          context "when using :currency locale backend" do
            around(:each) do |example|
              begin
                Money.locale_backend = :currency
                example.run
              ensure
                Money.locale_backend = :i18n
              end
            end

            it "does not validate with the locale's decimal mark" do
              transaction.amount = "123,45"
              expect(transaction.valid?).to be_falsey
            end

            it "validates with the currency's decimal mark" do
              transaction.amount = "123.45"
              expect(transaction.valid?).to be_truthy
            end

            it "does not validate with the locale's currency symbol" do
              transaction.amount = "€123"
              expect(transaction.valid?).to be_falsey
            end

            it "validates with the transaction's currency symbol" do
              transaction.amount = "$123"
              expect(transaction.valid?).to be_truthy
            end
          end
        end
      end
    end

    describe ".register_currency" do
      it "attaches currency at model level" do
        expect(Product.currency).to eq(Money::Currency.find(:usd))
        expect(DummyProduct.currency).to eq(Money::Currency.find(:gbp))
      end
    end

    describe "#read_monetized" do
      it "returns monetized attribute's value" do
        reduced_price = product.read_monetized(:reduced_price, :reduced_price_cents)

        expect(reduced_price).to be_an_instance_of(Money)
        expect(reduced_price).to eq(Money.new(product.reduced_price_cents, product.reduced_price_currency))
      end

      context "memoize" do
        it "memoizes monetized attribute's value" do
          product.instance_variable_set '@reduced_price', nil
          reduced_price = product.read_monetized(:reduced_price, :reduced_price_cents)

          expect(product.instance_variable_get('@reduced_price')).to eq(reduced_price)
        end

        it "resets memoized attribute's value if amount has changed" do
          reduced_price = product.read_monetized(:reduced_price, :reduced_price_cents)
          product.reduced_price_cents = 100

          expect(product.read_monetized(:reduced_price, :reduced_price_cents)).not_to eq(reduced_price)
        end

        it "resets memoized attribute's value if currency has changed" do
          reduced_price = product.read_monetized(:reduced_price, :reduced_price_cents)
          product.reduced_price_currency = 'CAD'

          expect(product.read_monetized(:reduced_price, :reduced_price_cents)).not_to eq(reduced_price)
        end
      end

      context "with preserve_user_input set" do
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
        let(:service) do
          Service.create(discount_cents: nil)
        end
        let(:default_currency_lambda) { double("Default Currency Fallback") }
        subject { service.read_monetized(:discount, :discount_cents, options) }

        around(:each) do |example|
          service # Instantiate instance which relies on Money.default_currency
          original_default_currency = Money.default_currency
          Money.default_currency = -> { default_currency_lambda.read_currency }
          example.run
          Money.default_currency = original_default_currency
        end

        context "when allow_nil options is set" do
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

        expect(product.price).to eq(nil)
      end

      it "sets monetized attribute to 0 when given a blank value" do
        currency = product.price.currency
        product.write_monetized :price, :price_cents, nil, false, nil, {}

        expect(product.price.amount).to eq(0)
        expect(product.price.currency).to eq(currency)
      end

      it "does not memoize monetized attribute's value if currency is read-only" do
        product.write_monetized :price, :price_cents, value, false, nil, {}

        price = product.instance_variable_get('@price')

        expect(price).to be_an_instance_of(Money)
        expect(price.amount).not_to eq(value.amount)
      end

      describe "instance_currency_name" do
        it "updates instance_currency_name attribute" do
          product.write_monetized :sale_price, :sale_price_amount, value, false, :sale_price_currency_code, {}

          expect(product.sale_price).to eq(value)
          expect(product.sale_price_currency_code).to eq('LVL')
        end

        it "memoizes monetized attribute's value with currency" do
          product.write_monetized :sale_price, :sale_price_amount, value, false, :sale_price_currency_code, {}

          expect(product.instance_variable_get('@sale_price')).to eq(value)
        end

        it "ignores empty instance_currency_name" do
          product.write_monetized :sale_price, :sale_price_amount, value, false, '', {}

          expect(product.sale_price.amount).to eq(value.amount)
          expect(product.sale_price.currency).to eq(Product.currency)
        end

        it "ignores instance_currency_name that model does not respond to" do
          product.write_monetized :sale_price, :sale_price_amount, value, false, :non_existing_currency, {}

          expect(product.sale_price.amount).to eq(value.amount)
          expect(product.sale_price.currency).to eq(Product.currency)
        end
      end

      describe "error handling" do
        let!(:old_price_value) { product.price }

        it "ignores values that do not implement to_money method" do
          product.write_monetized :price, :price_cents, [10], false, nil, {}

          expect(product.price).to eq(old_price_value)
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

            expect(product.price).to eq(old_price_value)
          end

          it "raises a MoneyRails::Error error when trying to set invalid currency" do
            allow(product).to receive(:currency_for_price).and_return('INVALID_CURRENCY')
            product.write_monetized :price, :price_cents, 10, false, nil, {}

            # Can not use public accessor here because currency_for_price is stubbed
            expect(product.instance_variable_get('@price')).to eq(old_price_value)
          end
        end
      end
    end

    describe "#currency_for" do
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

      it "falls back to a registered currency" do
        product = Product.new
        currency = product.send(:currency_for, :amount, nil, nil)

        expect(currency).to eq(Product.currency)
      end

      it "falls back to a default currency" do
        transaction = Transaction.new
        currency = transaction.send(:currency_for, :amount, nil, nil)

        expect(currency).to eq(Money.default_currency)
      end
    end
  end
end
