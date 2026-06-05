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
    end
  end
end
