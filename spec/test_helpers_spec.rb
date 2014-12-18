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
        expect(product).to monetize(:price_cents)
      end

      it "matches model attribute specified by :as chain" do
        expect(product).to monetize(:discount).as(:discount_value)
      end

      it "matches model attribute with nil value specified by :allow_nil chain" do
        expect(product).to monetize(:optional_price).allow_nil
      end

      it "matches nullable model attribute when tested instance has a non-nil value" do
        expect(product).to monetize(:optional_price).allow_nil
      end

      it "matches model attribute with currency specified by :with_currency chain" do
        expect(product).to monetize(:bonus_cents).with_currency(:gbp)
      end

      it "does not match non existed attribute" do
        expect(product).not_to monetize(:price_fake)
      end

      it "does not match wrong currency iso" do
        expect(product).not_to monetize(:bonus_cents).with_currency(:usd)
      end

      it "does not match wrong money attribute name" do
        expect(product).not_to monetize(:bonus_cents).as(:bonussss)
      end

      context "using subject" do
        subject { product }

        it { is_expected.to monetize(:price_cents) }
      end
    end
  end
end
