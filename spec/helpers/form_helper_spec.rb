require 'spec_helper'

if defined? ActiveRecord
  describe "Test helper in form blocks" do

    let :product do
      Product.create(:price_cents => 3000, :discount => 150,
                     :bonus_cents => 200, :optional_price => 100,
                     :sale_price_amount => 1200)
    end

    context "textfield" do
      it "uses the current value of money field in textfield" do
        helper.instance_variable_set :@product, product
        helper.text_field(:product, :price).should =~ /value=\"#{product.price.to_s}\"/
      end
    end
  end
end
