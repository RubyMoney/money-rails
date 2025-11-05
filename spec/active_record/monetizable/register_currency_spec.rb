# encoding: utf-8

require 'spec_helper'

if defined? ActiveRecord
  describe MoneyRails::ActiveRecord::Monetizable do
    describe ".register_currency" do
      it "attaches currency at model level" do
        usd_currency = Money::Currency.find(:usd)
        gbp_currency = Money::Currency.find(:gbp)

        expect(Product.currency).to eq(usd_currency)
        expect(DummyProduct.currency).to eq(gbp_currency)
      end
    end
  end
end
