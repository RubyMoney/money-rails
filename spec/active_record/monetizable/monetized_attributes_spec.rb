# frozen_string_literal: true

require "spec_helper"

if defined? ActiveRecord
  describe MoneyRails::ActiveRecord::Monetizable do
    describe ".monetized_attributes" do
      it "adds methods to the inheritance chain" do
        my_class = Class.new(ActiveRecord::Base) do
          self.table_name = :products
          monetize :price_cents
          attr_reader :side_effect

          def price=(value)
            @side_effect = true
            super
          end
        end

        p = my_class.new(price: 10)
        expect(p.price).to eq Money.new(10_00)
        expect(p.side_effect).to be_truthy
      end

      it "is inherited by subclasses" do
        sub_class = Class.new(Product)
        assert_monetized_attributes(
          sub_class.monetized_attributes,
          Product.monetized_attributes,
        )
      end

      it "is inherited by subclasses with new monetized attribute" do
        inherited_class = Class.new(Product) do
          monetize :special_price_cents
        end

        assert_monetized_attributes(
          inherited_class.monetized_attributes,
          Product.monetized_attributes.merge(special_price: "special_price_cents"),
        )
      end

      def assert_monetized_attributes(monetized_attributes, expected_attributes)
        expect(monetized_attributes).to include expected_attributes
        expect(expected_attributes).to include monetized_attributes
        expect(monetized_attributes.size).to eql expected_attributes.size
        monetized_attributes.each_key do |key|
          expect(key.is_a?(String)).to be_truthy
        end
      end
    end
  end
end
