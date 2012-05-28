require 'spec_helper'

describe MoneyRails::ActiveRecord::Monetizable do

  describe "monetize" do
    before :each do
      @product = Product.create(:price_cents => 3000, :discount => 150,
                                :bonus_cents => 200)
      @service = Service.create(:charge_cents => 2000, :discount_cents => 120)
    end

    it "attaches a Money object to model field" do
      @product.price.should be_an_instance_of(Money)
      @product.discount_value.should be_an_instance_of(Money)
      @product.bonus.should be_an_instance_of(Money)
    end

    it "returns the expected money amount as a Money object" do
      @product.price.should == Money.new(3000)
    end

    it "assigns the correct value from a Money object" do
      @product.price = Money.new(3210, "EUR")
      @product.save.should be_true
      @product.price_cents.should == 3210
    end

    it "respects :as argument" do
      @product.discount_value.should == Money.new(150)
    end

    it "uses numericality validation" do
      @product.price_cents = "foo"
      @product.save.should be_false

      @product.price_cents = 2000
      @product.save.should be_true
    end

    it "uses Money default currency if :with_currency has not been used" do
      @service.discount.currency.should == Money::Currency.find(:eur)
    end

    it "overrides default currency with the value of :with_currency argument" do
      @service.charge.currency.should == Money::Currency.find(:usd)
      @product.bonus.currency.should == Money::Currency.find(:usd)
    end

    context "for model with currency column:" do
      before :each do
        @transaction = Transaction.create(:amount_cents => 2400, :tax_cents => 600,
                                          :currency => :usd)
      end

      it "overrides default currency with the value of row currency" do
        @transaction.amount.currency.should == Money::Currency.find(:usd)
      end

      it "constructs the money attribute from the stored mapped attribute values" do
        @transaction.amount.should == Money.new(2400, :usd)
      end

      it "instantiates correctly Money objects from the mapped attributes" do
        t = Transaction.new(:amount_cents => 2500, :currency => "CAD")
        t.amount.should == Money.new(2500, "CAD")
      end

      it "assigns correctly Money objects to the attribute" do
        @transaction.amount = Money.new(2500, :eur)
        @transaction.save.should be_true
        @transaction.amount.cents.should == Money.new(2500, :eur).cents
        @transaction.amount.currency_as_string.should == "EUR"
      end

      it "raises exception if a non Money object is assigned to the attribute" do
        expect { @transaction.amount = "not a Money object" }.to raise_error(ArgumentError)
        expect { @transaction.amount = 234 }.to raise_error(ArgumentError)
      end

    end
  end
end
