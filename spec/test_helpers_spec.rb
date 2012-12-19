# -*- encoding : utf-8 -*-
require 'spec_helper'

if defined? ActiveRecord
  describe 'TestHelpers' do

    require "money-rails/test_helpers"
    include MoneyRails::TestHelpers

    let(:product) do
      Product.create(:price_cents => 3000, :discount => 150,
                     :bonus_cents => 200, :optional_price => 100,
                     :sale_price_amount => 1200)
    end

    describe "monetize matcher" do

      it "matches model attribute without a '_cents' suffix by default" do
        monetize(:price_cents).should be_true
      end

      it "matches model attribute specified by :as chain" do
        monetize(:price_cents).as(:discount_value).should be_true
      end

      it "matches model attribute with currency specified by :with_currency chain" do
        monetize(:price_cents).with_currency(:gbp).should be_true
      end
    end
  end
end
