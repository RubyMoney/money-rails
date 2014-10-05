require 'spec_helper'

class Sub < Product; end

if defined? ActiveRecord
  describe MoneyRails::ActiveRecord::Monetizable do
    describe "monetize" do
      let(:product) do
        Product.create(:price_cents => 3000, :discount => 150,
                       :bonus_cents => 200, :optional_price => 100,
                       :sale_price_amount => 1200)
      end

      let(:service) do
        Service.create(:charge_cents => 2000, :discount_cents => 120)
      end

      it "should be inherited by subclasses" do
        Sub.monetized_attributes.should == Product.monetized_attributes
      end

      it "attaches a Money object to model field" do
        product.price.should be_an_instance_of(Money)
        product.discount_value.should be_an_instance_of(Money)
        product.bonus.should be_an_instance_of(Money)
      end

      it "returns the expected money amount as a Money object" do
        product.price.should == Money.new(3000, "USD")
      end

      it "assigns the correct value from a Money object" do
        product.price = Money.new(3210, "USD")
        product.save.should eq(true)
        product.price_cents.should == 3210
      end

      it "assigns the correct value from a Money object using create" do
        product = Product.create(:price => Money.new(3210, "USD"), :discount => 150,
                                  :bonus_cents => 200, :optional_price => 100)
        product.valid?.should eq(true)
        product.price_cents.should == 3210
      end

      it "correctly updates from a Money object using update_attributes" do
        product.update_attributes(:price => Money.new(215, "USD")).should eq(true)
        product.price_cents.should == 215
      end

      it "should raise error if can't change currency" do
        product = Product.new
        expect {
          product.price = Money.new(10, "RUB")
        }.to raise_error("Can't change readonly currency 'USD' to 'RUB' for field 'price'")
      end

      it "respects :as argument" do
        product.discount_value.should == Money.new(150, "USD")
      end

      it "uses numericality validation" do
        product.price_cents = "foo"
        product.save.should eq(false)

        product.price_cents = 2000
        product.save.should eq(true)
      end

      it "skips numericality validation when disabled" do
        product.invalid_price_cents = 'not_valid'
        product.save.should eq(true)
      end

      it "passes validation after updating fractional attribute which was previously invalid" do
        product.price_in_a_range = -5
        product.should_not be_valid
        product.price_in_a_range_cents = 500
        product.should be_valid
      end

      context "when MoneyRails.raise_error_on_money_parsing is true" do
        before { MoneyRails.raise_error_on_money_parsing = true }
        after { MoneyRails.raise_error_on_money_parsing = false }

        it "raises exception when a String value with hyphen is assigned" do
          expect { product.invalid_price = "10-235" }.to raise_error
        end
      end

      context "when MoneyRails.raise_error_on_money_parsing is false (default)" do
        it "does not raise exception when a String value with hyphen is assigned" do
          expect { product.invalid_price = "10-235" }.not_to raise_error
        end
      end

      it "respects numericality validation when using update_attributes" do
        product.update_attributes(:price_cents => "some text").should eq(false)
        product.update_attributes(:price_cents => 2000).should eq(true)
      end

      it "uses numericality validation on money attribute" do
        product.price = "some text"
        product.save.should eq(false)

        product.price = Money.new(320, "USD")
        product.save.should eq(true)

        product.sale_price = "12.34"
        product.sale_price_currency_code = 'EUR'
        product.valid?.should eq(true)
      end

      it "fails validation with the proper error message if money value is invalid decimal" do
        product.price = "12.23.24"
        product.save.should eq(false)
        product.errors[:price].first.should match(/Must be a valid/)
        product.errors[:price].first.should match(/Got 12.23.24/)
      end

      it "fails validation with the proper error message if money value is nothing but periods" do
        product.price = "..."
        product.save.should eq(false)
        product.errors[:price].first.should match(/Must be a valid/)
        product.errors[:price].first.should match(/Got .../)
      end

      it "fails validation with the proper error message if money value has invalid thousands part" do
        product.price = "12,23.24"
        product.save.should eq(false)
        product.errors[:price].first.should match(/Must be a valid/)
        product.errors[:price].first.should match(/Got 12,23.24/)
      end

      it "passes validation if money value is a Float and the currency decimal mark is not period" do
        # The corresponding String would be "12,34" euros
        service.discount = 12.34
        service.save.should eq(true)
      end

       it "passes validation if money value is a Float" do
        product.price = 12.34
        product.save.should eq(true)
      end

      it "passes validation if money value is an Integer" do
        product.price = 12
        product.save.should eq(true)
      end

      it "fails validation with the proper error message using numericality validations" do
        product.price_in_a_range = "-12"
        product.valid?.should eq(false)
        product.errors[:price_in_a_range].first.should match(/Must be greater than zero and less than \$100/)

        product.price_in_a_range = Money.new(-1200, "USD")
        product.valid?.should eq(false)
        product.errors[:price_in_a_range].first.should match(/Must be greater than zero and less than \$100/)

        product.price_in_a_range = "0"
        product.valid?.should eq(false)
        product.errors[:price_in_a_range].first.should match(/Must be greater than zero and less than \$100/)

        product.price_in_a_range = "12"
        product.valid?.should eq(true)

        product.price_in_a_range = Money.new(1200, "USD")
        product.valid?.should eq(true)

        product.price_in_a_range = "101"
        product.valid?.should eq(false)
        product.errors[:price_in_a_range].first.should match(/Must be greater than zero and less than \$100/)

        product.price_in_a_range = Money.new(10100, "USD")
        product.valid?.should eq(false)
        product.errors[:price_in_a_range].first.should match(/Must be greater than zero and less than \$100/)
      end

      it "fails validation with the proper error message using validates :money" do
        product.validates_method_amount = "-12"
        product.valid?.should eq(false)
        product.errors[:validates_method_amount].first.should match(/Must be greater than zero and less than \$100/)

        product.validates_method_amount = Money.new(-1200, "USD")
        product.valid?.should eq(false)
        product.errors[:validates_method_amount].first.should match(/Must be greater than zero and less than \$100/)

        product.validates_method_amount = "0"
        product.valid?.should eq(false)
        product.errors[:validates_method_amount].first.should match(/Must be greater than zero and less than \$100/)

        product.validates_method_amount = "12"
        product.valid?.should eq(true)

        product.validates_method_amount = Money.new(1200, "USD")
        product.valid?.should eq(true)

        product.validates_method_amount = "101"
        product.valid?.should eq(false)
        product.errors[:validates_method_amount].first.should match(/Must be greater than zero and less than \$100/)

        product.validates_method_amount = Money.new(10100, "USD")
        product.valid?.should eq(false)
        product.errors[:validates_method_amount].first.should match(/Must be greater than zero and less than \$100/)
      end

      it "fails validation with the proper error message on the cents field " do
        product.price_in_a_range = "-12"
        product.valid?.should eq(false)
        product.errors[:price_in_a_range_cents].first.should match(/greater than 0/)

        product.price_in_a_range = "0"
        product.valid?.should eq(false)
        product.errors[:price_in_a_range_cents].first.should match(/greater than 0/)

        product.price_in_a_range = "12"
        product.valid?.should eq(true)

        product.price_in_a_range = "101"
        product.valid?.should eq(false)
        product.errors[:price_in_a_range_cents].first.should match(/less than or equal to 10000/)
      end

      it "fails validation when a non number string is given" do
        product = Product.create(:price_in_a_range => "asd")
        product.valid?.should eq(false)
        product.errors[:price_in_a_range].first.should match(/greater than zero/)

        product = Product.create(:price_in_a_range => "asd23")
        product.valid?.should eq(false)
        product.errors[:price_in_a_range].first.should match(/greater than zero/)

        product = Product.create(:price => "asd")
        product.valid?.should eq(false)
        product.errors[:price].first.should match(/is not a number/)

        product = Product.create(:price => "asd23")
        product.valid?.should eq(false)
        product.errors[:price].first.should match(/is not a number/)
      end

      it "passes validation when amount contains spaces (99 999 999.99)" do
        product.price = "99 999 999.99"
        product.should be_valid
        product.price_cents.should == 9999999999
      end

      it "passes validation when amount contains underscores (99_999_999.99)" do
        product.price = "99_999_999.99"
        product.should be_valid
        product.price_cents.should == 9999999999
      end

      it "passes validation if money value has correct format" do
        product.price = "12,230.24"
        product.save.should eq(true)
      end

      it "passes validation if there is a whitespace between the currency symbol and amount" do
        product.price = "$ 123,456.78"
        product.save.should eq(true)
      end

      it "respects numericality validation when using update_attributes on money attribute" do
        product.update_attributes(:price => "some text").should eq(false)
        product.update_attributes(:price => Money.new(320, 'USD')).should eq(true)
      end

      it "uses i18n currency format when validating" do
        old_locale = I18n.locale

        I18n.locale = "en-GB"
        Money.default_currency = Money::Currency.find('EUR')
        "12.00".to_money.should == Money.new(1200, :eur)
        transaction = Transaction.new(amount: "12.00", tax: "13.00")
        transaction.amount_cents.should == 1200
        transaction.valid?.should eq(true)

        # reset locale setting
        I18n.locale = old_locale
      end

      it "defaults to Money::Currency format when no I18n information is present" do
        old_locale = I18n.locale

        I18n.locale = "zxsw"
        Money.default_currency = Money::Currency.find('EUR')
        "12,00".to_money.should == Money.new(1200, :eur)
        transaction = Transaction.new(amount: "12,00", tax: "13,00")
        transaction.amount_cents.should == 1200
        transaction.valid?.should eq(true)

        # reset locale setting
        I18n.locale = old_locale
      end

      it "doesn't allow nil by default" do
        product.price_cents = nil
        product.save.should eq(false)
      end

      it "allows nil if optioned" do
        product.optional_price = nil
        product.save.should eq(true)
        product.optional_price.should be_nil
      end

      it "doesn't raise exception if validation is used and nil is not allowed" do
        expect { product.price = nil }.to_not raise_error
      end

      it "doesn't save nil values if validation is used and nil is not allowed" do
        product.price = nil
        product.save
        product.price_cents.should_not be_nil
      end

      it "resets money_before_type_cast attr every time a save operation occurs" do
        v = Money.new(100, :usd)
        product.price = v
        product.price_money_before_type_cast.should == v
        product.save
        product.price_money_before_type_cast.should be_nil
        product.price = 10
        product.price_money_before_type_cast.should == 10
        product.save
        product.price_money_before_type_cast.should be_nil
      end

      it "does not reset money_before_type_cast attr if save operation fails" do
        product.bonus = ""
        product.bonus_money_before_type_cast.should == ""
        product.save.should eq(false)
        product.bonus_money_before_type_cast.should == ""
      end

      it "uses Money default currency if :with_currency has not been used" do
        service.discount.currency.should == Money::Currency.find(:eur)
      end

      it "overrides default currency with the currency registered for the model" do
        product.price.currency.should == Money::Currency.find(:usd)
      end

      it "overrides default currency with the value of :with_currency argument" do
        service.charge.currency.should == Money::Currency.find(:usd)
        product.bonus.currency.should == Money::Currency.find(:gbp)
      end

      it "correctly assigns Money objects to the attribute" do
        product.price = Money.new(2500, :USD)
        product.save.should eq(true)
        product.price.cents.should == 2500
        product.price.currency_as_string.should == "USD"
      end

      it "correctly assigns Fixnum objects to the attribute" do
        product.price = 25
        product.save.should eq(true)
        product.price.cents.should == 2500
        product.price.currency_as_string.should == "USD"

        service.discount = 2
        service.save.should eq(true)
        service.discount.cents.should == 200
        service.discount.currency_as_string.should == "EUR"
      end

      it "correctly assigns String objects to the attribute" do
        product.price = "25"
        product.save.should eq(true)
        product.price.cents.should == 2500
        product.price.currency_as_string.should == "USD"

        service.discount = "2"
        service.save.should eq(true)
        service.discount.cents.should == 200
        service.discount.currency_as_string.should == "EUR"
      end

      it "overrides default, model currency with the value of :with_currency in fixnum assignments" do
        product.bonus = 25
        product.save.should eq(true)
        product.bonus.cents.should == 2500
        product.bonus.currency_as_string.should == "GBP"

        service.charge = 2
        service.save.should eq(true)
        service.charge.cents.should == 200
        service.charge.currency_as_string.should == "USD"
      end

      it "overrides default, model currency with the value of :with_currency in string assignments" do
        product.bonus = "25"
        product.save.should eq(true)
        product.bonus.cents.should == 2500
        product.bonus.currency_as_string.should == "GBP"

        service.charge = "2"
        service.save.should eq(true)
        service.charge.cents.should == 200
        service.charge.currency_as_string.should == "USD"
      end

      it "overrides default currency with model currency, in fixnum assignments" do
        product.discount_value = 5
        product.save.should eq(true)
        product.discount_value.cents.should == 500
        product.discount_value.currency_as_string.should == "USD"
      end

      it "overrides default currency with model currency, in string assignments" do
        product.discount_value = "5"
        product.save.should eq(true)
        product.discount_value.cents.should == 500
        product.discount_value.currency_as_string.should == "USD"
      end

      it "falls back to default currency, in fixnum assignments" do
        service.discount = 5
        service.save.should eq(true)
        service.discount.cents.should == 500
        service.discount.currency_as_string.should == "EUR"
      end

      it "falls back to default currency, in string assignments" do
        service.discount = "5"
        service.save.should eq(true)
        service.discount.cents.should == 500
        service.discount.currency_as_string.should == "EUR"
      end

      it "sets field to nil, in nil assignments if allow_nil is set" do
        product.optional_price = nil
        product.save.should eq(true)
        product.optional_price.should be_nil
      end

      it "sets field to nil, in instantiation if allow_nil is set" do
        pr = Product.new(:optional_price => nil, :price_cents => 5320,
          :discount => 350, :bonus_cents => 320)
        pr.optional_price.should be_nil
        pr.save.should eq(true)
        pr.optional_price.should be_nil
      end

      it "sets field to nil, in blank assignments if allow_nil is set" do
        product.optional_price = ""
        product.save.should eq(true)
        product.optional_price.should be_nil
      end


      context "when the monetized field is an aliased attribute" do
        it "writes the subunits to the original (unaliased) column" do
          product.renamed = "$10.00"
          expect(product.aliased_cents).to eq 10_00
        end
      end

      context "for column with model currency:" do
        it "has default currency if not specified" do
          product = Product.create(:sale_price_amount => 1234)
          product.sale_price.currency_as_string == 'USD'
        end

        it "is overridden by instance currency column" do
          product = Product.create(:sale_price_amount => 1234,
                                   :sale_price_currency_code => 'CAD')
          product.sale_price.currency_as_string.should == 'CAD'
        end

        it 'can change currency of custom column' do
          product = Product.create!(
            :price => Money.new(10,'USD'),
            :bonus => Money.new(10,'GBP'),
            :discount => 10,
            :sale_price_amount => 1234,
            :sale_price_currency_code => 'USD')

          product.sale_price.currency_as_string.should == 'USD'

          product.sale_price = Money.new 456, 'CAD'
          product.save
          product.reload

          product.sale_price.currency_as_string.should == 'CAD'
          product.discount_value.currency_as_string.should == 'USD'
        end
      end

      context "for model with currency column:" do
        let(:transaction) do
          Transaction.create(:amount_cents => 2400, :tax_cents => 600,
                             :currency => :usd)
        end

        let(:dummy_product) do
          DummyProduct.create(:price_cents => 2400, :currency => :usd)
        end

        let(:dummy_product_with_nil_currency) do
          DummyProduct.create(:price_cents => 2600) # nil currency
        end

        let(:dummy_product_with_invalid_currency) do
          # invalid currency
          DummyProduct.create(:price_cents => 2600, :currency => :foo)
        end

        it "correctly serializes the currency to a new instance of model" do
          d = DummyProduct.new
          d.price = Money.new(10, "EUR")
          d.save!
          d.reload
          d.currency.should == "EUR"
        end

        it "overrides default currency with the value of row currency" do
          transaction.amount.currency.should == Money::Currency.find(:usd)
        end

        it "overrides default currency with the currency registered for the model" do
          dummy_product_with_nil_currency.price.currency.should ==
            Money::Currency.find(:gbp)
        end

        it "overrides default currency with the currency registered for the model if currency is invalid" do
          dummy_product_with_invalid_currency.price.currency.should ==
            Money::Currency.find(:gbp)
        end

        it "overrides default and model currency with the row currency" do
          dummy_product.price.currency.should == Money::Currency.find(:usd)
        end

        it "constructs the money attribute from the stored mapped attribute values" do
          transaction.amount.should == Money.new(2400, :usd)
        end

        it "correctly instantiates Money objects from the mapped attributes" do
          t = Transaction.new(:amount_cents => 2500, :currency => "CAD")
          t.amount.should == Money.new(2500, "CAD")
        end

        it "correctly assigns Money objects to the attribute" do
          transaction.amount = Money.new(2500, :eur)
          transaction.save.should eq(true)
          transaction.amount.cents.should == Money.new(2500, :eur).cents
          transaction.amount.currency_as_string.should == "EUR"
        end

        it "uses default currency if a non Money object is assigned to the attribute" do
          transaction.amount = 234
          transaction.amount.currency_as_string.should == "USD"
        end

        it "constructs the money object from the mapped method value" do
          transaction.total.should == Money.new(3000, :usd)
        end

      end
    end

    describe "register_currency" do
      it "attaches currency at model level" do
        Product.currency.should == Money::Currency.find(:usd)
        DummyProduct.currency.should == Money::Currency.find(:gbp)
      end
    end
  end
end
