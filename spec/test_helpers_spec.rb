# -*- encoding : utf-8 -*-
require 'spec_helper'

if defined? ActiveRecord
  describe 'TestHelpers' do

    require "money-rails/test_helpers"
    include MoneyRails::TestHelpers

    let(:product) do
      Product.create(:price_cents => 3000, :discount => 150,
                     :bonus_cents => 200,
                     :sale_price_amount => 1200)
    end

    describe "monetize matcher" do
      it "matches model attribute without a '_cents' suffix by default" do
        product.should monetize(:price_cents)
      end

      it "matches model attribute specified by :as chain" do
        product.should monetize(:discount).as(:discount_value)
      end

      it "matches model attribute with nil value specified by :allow_nil chain" do
        product.should monetize(:optional_price).allow_nil
      end

      it "matches model attribute with currency specified by :with_currency chain" do
        product.should monetize(:bonus_cents).with_currency(:gbp)
      end

      it "does not match non existed attribute" do
        product.should_not monetize(:price_fake)
      end

      it "does not match wrong currency iso" do
        product.should_not monetize(:bonus_cents).with_currency(:usd)
      end

      it "does not match wrong money attribute name" do
        product.should_not monetize(:bonus_cents).as(:bonussss)
      end

      context "using subject" do
        subject { product }

        it { should monetize(:price_cents) }
      end
    end
  end
end
