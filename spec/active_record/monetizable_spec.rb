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

    describe ".monetize" do
      let(:service) do
        Service.create(charge_cents: 2000, discount_cents: 120)
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

      it "correctly updates from a Money object using update" do
        expect(product.update(price: Money.new(215, "USD"))).to be_truthy
        expect(product.price_cents).to eq(215)
      end

      it "assigns the correct value from params" do
        params_clp = { amount: "20000", tax: "1000", currency: "CLP" }
        product = Transaction.create(params_clp)
        expect(product.valid?).to be_truthy
        expect(product.amount.currency.subunit_to_unit).to eq(1)
        expect(product.amount_cents).to eq(20000)
      end

      # TODO: This is a slightly controversial example, btu it reflects the current behaviour
      it "re-assigns cents amount when subunit/unit ratio changes preserving amount in units" do
        transaction = Transaction.create(amount: "20000", tax: "1000", currency: "USD")

        expect(transaction.amount).to eq(Money.new(20000_00, "USD"))

        transaction.currency = "CLP"

        expect(transaction.amount).to eq(Money.new(20000, "CLP"))
        expect(transaction.amount_cents).to eq(20000)
      end

      it "update to instance currency field gets applied to converted methods" do
        transaction = Transaction.create(amount: "200", tax: "10", currency: "USD")
        expect(transaction.total).to eq(Money.new(21000, "USD"))

        transaction.currency = "CLP"
        expect(transaction.total).to eq(Money.new(210, "CLP"))
      end

      it "raises an error if trying to create two attributes with the same name" do
        expect do
          Product.class_eval do
            monetize :discount, as: :price
          end
        end.to raise_error(
          ArgumentError,
          "Product already has a monetized attribute called 'price'",
        )
      end

      it "raises an error if Money object has the same attribute name as the monetizable attribute" do
        expect do
          Class.new(Product) do
            monetize :price_cents, as: :price_cents
          end
        end.to raise_error(
          ArgumentError,
          "monetizable attribute name cannot be the same as options[:as] parameter",
        )
      end

      context "with custom postfix" do
        around do |example|
          old_postfix = MoneyRails::Configuration.amount_column[:postfix]
          MoneyRails::Configuration.amount_column[:postfix] = "_pennies"
          example.call
          MoneyRails::Configuration.amount_column[:postfix] = old_postfix
        end

        it "raises an error when unable to infer attribute name" do
          expect do
            Class.new(Product) do
              monetize :price_cents
            end
          end.to raise_error(
            ArgumentError,
            /\AUnable to infer the name of the monetizable attribute for 'price_cents'./,
          )
        end
      end

      it "allows subclass to redefine attribute with the same name" do
        sub_product_class = Class.new(Product) do
          monetize :discount, as: :discount_price, with_currency: :gbp
        end

        sub_product = sub_product_class.new(discount: 100)

        expect(sub_product.discount_price).to be_an_instance_of(Money)
        expect(sub_product.discount_price.currency.id).to equal :gbp
      end

      it "respects :as argument" do
        expect(product.discount_value).to eq(Money.new(150, "USD"))
      end

      it "doesn't allow nil by default" do
        product.price_cents = nil
        expect(product.save).to be_falsey
      end

      it "doesn't raise exception if validation is used and nil is not allowed" do
        expect { product.price = nil }.not_to raise_error
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
          product.renamed = "$10.00"
          expect(product.aliased_cents).to eq 10_00
        end
      end

      context "with a column with model currency" do
        it "has default currency if not specified" do
          product = Product.create(sale_price_amount: 1234)
          expect(product.sale_price.currency.to_s).to eq("USD")
        end

        it "is overridden by instance currency column" do
          product = Product.create(sale_price_amount: 1234,
                                   sale_price_currency_code: "CAD")
          expect(product.sale_price.currency.to_s).to eq("CAD")
        end

        it "can change currency of custom column" do
          product = Product.create!(
            price: Money.new(10, "USD"),
            bonus: Money.new(10, "GBP"),
            discount: 10,
            sale_price_amount: 1234,
            sale_price_currency_code: "USD",
          )

          expect(product.sale_price.currency.to_s).to eq("USD")

          product.sale_price = Money.new 456, "CAD"
          product.save
          product.reload

          expect(product.sale_price.currency.to_s).to eq("CAD")
          expect(product.discount_value.currency.to_s).to eq("USD")
        end
      end

      context "with a model with currency column" do
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
            Money::Currency.find(:gbp),
          )
        end

        it "overrides default currency with the currency registered for the model if currency is invalid" do
          expect(dummy_product_with_invalid_currency.price.currency).to eq(
            Money::Currency.find(:gbp),
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

        it "constructs the money object from the mapped method value with arguments" do
          expect(transaction.total(1, bar: 2)).to eq(Money.new(3003, :usd))
        end

        it "allows currency column postfix to be blank" do
          allow(MoneyRails::Configuration)
            .to receive(:currency_column)
            .and_return({ postfix: nil, column_name: "currency" })

          expect(dummy_product_with_nil_currency.price.currency)
            .to eq(Money::Currency.find(:gbp))
        end

        it "updates inferred currency column based on currency column postfix" do
          product.reduced_price = Money.new(999_00, "CAD")
          product.save

          expect(product.reduced_price_cents).to eq(999_00)
          expect(product.reduced_price_currency).to eq("CAD")
        end

        context "with a field with allow_nil: true" do
          it "doesn't set currency to nil when setting the field to nil" do
            t = Transaction.new(amount_cents: 2500, currency: "CAD")
            t.optional_amount = nil
            expect(t.currency).to eq("CAD")
          end
        end

        # TODO: these specs should mock locale_backend with expected values
        #       instead of manipulating it directly
        context "with an Italian locale" do
          around do |example|
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
            around do |example|
              Money.locale_backend = :currency
              example.run
            ensure
              Money.locale_backend = :i18n
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
  end
end
