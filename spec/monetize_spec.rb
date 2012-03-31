require 'spec_helper'

describe MoneyRails::Monetizable do

  describe "monetize" do
    before :each do
      @product = Product.create(:price_cents => 3000, :discount => 150)
    end

    it "attaches a Money object to model field" do
      @product.price.should == Money.new(3000)
    end

    it "respects :target_name argument" do
      @product.discount_value == Money.new(150)
    end
  end
end
