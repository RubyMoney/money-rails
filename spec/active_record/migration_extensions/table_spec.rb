require 'spec_helper'

class Item < ActiveRecord::Base; end

if defined? ActiveRecord
  describe MoneyRails::ActiveRecord::MigrationExtensions::SchemaStatements do
    before :all do
      @connection = ActiveRecord::Base.connection
      @connection.send :extend, MoneyRails::ActiveRecord::MigrationExtensions::SchemaStatements
    end

    describe 'money' do
      before do
        @connection.drop_table :items if @connection.table_exists? :items
        @connection.create_table :items do |t|
          t.money :price
          t.money :price_without_currency, currency: { present: false }
          t.money :price_with_full_options, amount: {
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
        end

        Item.reset_column_information
      end

      context 'default options' do
        describe 'amount' do
          subject { Item.columns_hash['price_cents'] }

          it { expect(subject.default).to eq(0) }
          it { expect(subject.null).to be(false) }
          it { expect(subject.type).to eq(:integer) }
        end

        describe 'currency' do
          subject { Item.columns_hash['price_currency'] }

          # set in spec/dummy/config/initializers/money.rb
          it { expect(subject.default).to eq('EUR') }

          it { expect(subject.null).to be(false) }
          it { expect(subject.type).to eq(:string) }
        end
      end

      context 'without currency column' do
        it { Item.columns_hash['price_without_currency_cents'].should_not be nil }
        it { Item.columns_hash['price_without_currency_currency'].should be nil }
      end

      context 'full options' do
        describe 'amount' do
          subject { Item.columns_hash['prefix_price_with_full_options_postfix'] }

          it { expect(subject.default).to eq(1) }
          it { expect(subject.null).to be(true) }
          it { expect(subject.type).to eq(:decimal) }
          it { expect(subject.precision).to eq(4) }
          it { expect(subject.scale).to eq(2) }
        end

        describe 'currency' do
          it { Item.columns_hash['currency'].should_not be nil }
        end
      end
    end

    describe 'remove_money' do
      before do
        @connection.change_table :items do |t|
          t.money :price
          t.money :price_without_currency, currency: { present: false }
          t.money :price_with_full_options, amount: { prefix: :prefix_, postfix: :_postfix }, currency: { column_name: :currency }

          t.remove_money :price
          t.remove_money :price_without_currency, currency: { present: false }
          t.remove_money :price_with_full_options, amount: { prefix: :prefix_, postfix: :_postfix }, currency: { column_name: :currency }
        end

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
