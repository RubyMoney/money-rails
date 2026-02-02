# frozen_string_literal: true

require "spec_helper"

if defined? ActiveRecord
  class Item < ActiveRecord::Base; end

  describe MoneyRails::ActiveRecord::MigrationExtensions::SchemaStatements do
    before :all do
      @connection = ActiveRecord::Base.connection
      @connection.drop_table :items if @connection.table_exists? :items
      @connection.create_table :items
      @connection.send :extend, described_class
    end

    describe "add_money" do
      before do
        @connection.add_money :items, :price
        @connection.add_money :items, :price_without_currency, currency: { present: false }
        @connection.add_money :items, :price_with_full_options, amount: {
          prefix: :prefix_,
          postfix: :_postfix,
          type: :decimal,
          precision: 4,
          scale: 2,
          default: 1,
          null: true,
        }, currency: {
          prefix: :currency_prefix,
          postfix: :currency_postfix,
          column_name: :currency,
        }

        Item.reset_column_information
      end

      context "with default options" do
        describe "amount" do
          let(:column) { Item.columns_hash["price_cents"] }

          it { expect(column.default.to_i).to eq(0) }
          it { expect(Item.new.public_send(column.name)).to eq(0) }
          it { expect(column.null).to be(false) }
          it { expect(column.type).to eq(:integer) }
        end

        describe "currency" do
          let(:column) { Item.columns_hash["price_currency"] }

          # set in spec/dummy/config/initializers/money.rb
          it { expect(column.default).to eq("EUR") }

          it { expect(column.null).to be(false) }
          it { expect(column.type).to eq(:string) }
        end
      end

      context "without currency column" do
        it { expect(Item.columns_hash["price_without_currency_cents"]).not_to be_nil }
        it { expect(Item.columns_hash["price_without_currency_currency"]).to be_nil }
      end

      context "with full options" do
        describe "amount" do
          let(:column) { Item.columns_hash["prefix_price_with_full_options_postfix"] }

          it { expect(column.default.to_i).to eq(1) }
          it { expect(Item.new.public_send(column.name)).to eq(1) }
          it { expect(column.null).to be(true) }
          it { expect(column.type).to eq(:decimal) }
          it { expect(column.precision).to eq(4) }
          it { expect(column.scale).to eq(2) }
        end

        describe "currency" do
          it { expect(Item.columns_hash["currency"]).not_to be_nil }
        end
      end
    end

    describe "remove_money" do
      before do
        @connection.add_money :items, :price
        @connection.add_money :items, :price_without_currency, currency: { present: false }
        @connection.add_money :items, :price_with_full_options, amount: { prefix: :prefix_, postfix: :_postfix }, currency: { column_name: :currency }

        @connection.remove_money :items, :price
        @connection.remove_money :items, :price_without_currency, currency: { present: false }
        @connection.remove_money :items, :price_with_full_options, amount: { prefix: :prefix_, postfix: :_postfix }, currency: { column_name: :currency }

        Item.reset_column_information
      end

      it { expect(Item.columns_hash["price_cents"]).to be_nil }
      it { expect(Item.columns_hash["price_currency"]).to be_nil }

      it { expect(Item.columns_hash["price_without_currency_cents"]).to be_nil }

      it { expect(Item.columns_hash["prefix_price_with_full_options_postfix"]).to be_nil }
      it { expect(Item.columns_hash["currency"]).to be_nil }
    end
  end
end
