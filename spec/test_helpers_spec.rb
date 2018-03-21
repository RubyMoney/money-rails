# -*- encoding : utf-8 -*-
require 'spec_helper'

if defined? ActiveRecord
  describe 'TestHelpers' do

    require "money-rails/test_helpers"
    include MoneyRails::TestHelpers

    let(:product) do
      Product.create(price_cents: 3000, discount: 150,
                     bonus_cents: 200,
                     sale_price_amount: 1200)
    end

    describe "monetize matcher" do

      shared_context "monetize matcher" do

        it "matches model attribute without a '_cents' suffix by default" do
          is_expected.to monetize(:price)
        end

        it "matches model attribute specified by :as chain" do
          is_expected.to monetize(:discount).as(:discount_value)
        end

        it "matches model attribute with nil value specified by :allow_nil chain" do
          is_expected.to monetize(:optional_price).allow_nil
        end

        it "matches nullable model attribute when tested instance has a non-nil value" do
          is_expected.to monetize(:optional_price).allow_nil
        end

        it "matches model attribute with currency specified by :with_currency chain" do
          is_expected.to monetize(:bonus).with_currency(:gbp)
        end

        it "matches model attribute with currency attribute specified by :with_model_currency chain" do
          is_expected.to(
            monetize(:sale_price_amount)
              .as(:sale_price)
              .with_model_currency(:sale_price_currency_code)
          )
        end

        it "does not match non existed attribute" do
          is_expected.not_to monetize(:price_fake)
        end

        it "does not match wrong currency iso" do
          is_expected.not_to monetize(:bonus).with_currency(:usd)
        end

        it "does not match wrong money attribute name" do
          is_expected.not_to monetize(:bonus).as(:bonussss)
        end
      end

      describe "testing against an instance of the model class" do
        subject { product }
        include_context "monetize matcher"
      end

      describe "testing against the model class itself" do
        subject { Product }
        include_context "monetize matcher"
      end
    end
  end
end
