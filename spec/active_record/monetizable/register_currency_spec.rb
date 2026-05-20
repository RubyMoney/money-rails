# frozen_string_literal: true

require "spec_helper"

if defined? ActiveRecord
  describe MoneyRails::ActiveRecord::Monetizable do
    describe ".register_currency" do
      it "attaches currency at model level" do
        expect(Product.currency).to eq(Money::Currency.find(:usd))
        expect(DummyProduct.currency).to eq(Money::Currency.find(:gbp))
      end
    end
  end
end
