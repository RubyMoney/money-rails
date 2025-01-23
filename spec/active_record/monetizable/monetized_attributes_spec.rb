# encoding: utf-8

require 'spec_helper'

require_relative 'money_helpers'

if defined? ActiveRecord
  describe MoneyRails::ActiveRecord::Monetizable do
    include MoneyHelpers

    describe ".monetized_attributes" do

      class InheritedMonetizeProduct < Product
        monetize :special_price_cents
      end

      it "should be inherited by subclasses" do
        assert_monetized_attributes(Sub.monetized_attributes, Product.monetized_attributes)
      end

      it "should be inherited by subclasses with new monetized attribute" do
        assert_monetized_attributes(InheritedMonetizeProduct.monetized_attributes, Product.monetized_attributes.merge(special_price: "special_price_cents"))
      end

      def assert_monetized_attributes(monetized_attributes, expected_attributes)
        expect(monetized_attributes).to include expected_attributes
        expect(expected_attributes).to include monetized_attributes
        expect(monetized_attributes.size).to eql expected_attributes.size
        monetized_attributes.keys.each do |key|
          expect(key.is_a? String).to be_truthy
        end
      end
    end
  end
end
