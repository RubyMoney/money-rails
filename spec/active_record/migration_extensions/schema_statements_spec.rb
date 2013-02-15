require 'spec_helper'

class Item < ActiveRecord::Base; end

if defined? ActiveRecord
  describe MoneyRails::ActiveRecord::MigrationExtensions::SchemaStatements do
    before :all do
      @connection = ActiveRecord::Base.connection
      @connection.drop_table :items if @connection.table_exists? :items
      @connection.create_table :items
      @connection.send :extend, MoneyRails::ActiveRecord::MigrationExtensions::SchemaStatements
    end

    describe 'add_money' do
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
          null: true
        }, currency: {
          prefix: :currency_prefix,
          postfix: :currency_postfix,
          column_name: :currency
        }

        Item.reset_column_information
      end

      context 'default options' do
        describe 'amount' do
          subject { Item.columns_hash['price_cents'] }

          its (:default) { should eq 0 }
          its (:null) { should be_false }
          its (:type) { should eq :integer }
        end

        describe 'currency' do
          subject { Item.columns_hash['price_currency'] }

          # set in spec/dummy/config/initializers/money.rb
          its (:default) { should eq 'EUR' }

          its (:null) { should be_false }
          its (:type) { should eq :string }
        end
      end

      context 'without currency column' do
        it { Item.columns_hash['price_without_currency_cents'].should_not be nil }
        it { Item.columns_hash['price_without_currency_currency'].should be nil }
      end

      context 'full options' do
        describe 'amount' do
          subject { Item.columns_hash['prefix_price_with_full_options_postfix'] }

          its (:default) { should eq 1 }
          its (:null) { should be_true }
          its (:type) { should eq :decimal }
          its (:precision) { should eq 4 }
          its (:scale) { should eq 2 }
        end

        describe 'currency' do
          it { Item.columns_hash['currency'].should_not be nil }
        end
      end
    end

    describe 'remove_money' do
      before do
        @connection.add_money :items, :price
        @connection.add_money :items, :price_without_currency, currency: { present: false }
        @connection.add_money :items, :price_with_full_options, amount: { prefix: :prefix_, postfix: :_postfix }, currency: { column_name: :currency }

        @connection.remove_money :items, :price
        @connection.remove_money :items, :price_without_currency, currency: { present: false }
        @connection.remove_money :items, :price_with_full_options, amount: { prefix: :prefix_, postfix: :_postfix }, currency: { column_name: :currency }

        Item.reset_column_information
      end

      it { Item.columns_hash['price_cents'].should be nil }
      it { Item.columns_hash['price_currency'].should be nil }

      it { Item.columns_hash['price_without_currency_cents'].should be nil }

      it { Item.columns_hash['prefix_price_with_full_options_postfix'].should be nil }
      it { Item.columns_hash['currency'].should be nil }
    end
  end
end
