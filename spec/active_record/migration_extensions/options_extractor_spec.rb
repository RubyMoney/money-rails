# frozen_string_literal: true

require "spec_helper"
require "money-rails/active_record/migration_extensions/options_extractor"

if defined? ActiveRecord
  describe MoneyRails::ActiveRecord::MigrationExtensions::OptionsExtractor do
    describe ".extract" do
      subject(:result) { described_class.extract(attribute, table_name, accessor, options) }

      let(:table_name) { :products }
      let(:accessor)   { :price }
      let(:options)    { {} }

      context "with :amount attribute" do
        let(:attribute) { :amount }

        it "returns present as true" do
          expect(result[0]).to be(true)
        end

        it "returns the table name" do
          expect(result[1]).to eq(:products)
        end

        it "builds column_name from accessor and default postfix" do
          expect(result[2]).to eq("price_cents")
        end

        it "returns the default type :integer" do
          expect(result[3]).to eq(:integer)
        end

        it "includes null and default in column options" do
          expect(result[4]).to include(null: false, default: 0)
        end
      end

      context "with :currency attribute" do
        let(:attribute) { :currency }

        it "returns present as true" do
          expect(result[0]).to be(true)
        end

        it "builds column_name from accessor and default postfix" do
          expect(result[2]).to eq("price_currency")
        end

        it "returns the default type :string" do
          expect(result[3]).to eq(:string)
        end
      end

      context "with a custom prefix and postfix" do
        let(:attribute) { :amount }
        let(:options)   { { amount: { prefix: "pre_", postfix: "_post" } } }

        it "builds column_name using both prefix and postfix" do
          expect(result[2]).to eq("pre_price_post")
        end
      end

      context "with an explicit column_name" do
        let(:attribute) { :amount }
        let(:options)   { { amount: { column_name: "total_cents" } } }

        it "uses the explicit column_name over the auto-generated one" do
          expect(result[2]).to eq("total_cents")
        end
      end

      context "with present: false" do
        let(:attribute) { :currency }
        let(:options)   { { currency: { present: false } } }

        it "returns present as false" do
          expect(result[0]).to be(false)
        end
      end

      context "with extra column options" do
        let(:attribute) { :amount }
        let(:options)   { { amount: { type: :decimal, precision: 10, scale: 2 } } }

        it "overrides type from options" do
          expect(result[3]).to eq(:decimal)
        end

        it "passes precision and scale through to column options" do
          expect(result[4]).to include(precision: 10, scale: 2)
        end
      end

      context "with a string table name" do
        let(:attribute)  { :amount }
        let(:table_name) { "orders" }

        it "preserves the table name as given" do
          expect(result[1]).to eq("orders")
        end
      end
    end
  end
end
