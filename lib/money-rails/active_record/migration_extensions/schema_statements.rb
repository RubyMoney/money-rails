module MoneyRails
  module ActiveRecord
    module MigrationExtensions
      module SchemaStatements
        def add_money(table_name, accessor, options={})
          MoneyRails.deprecator.warn(<<-MSG.squish)
            `#t.add_money` is deprecated and will be removed in money-rails version 2. Either
            explicity name your money and currency columns `COLUMN_NAME_cents` and
            `COLUMN_NAME_currency` or pick a different name. If you pick the latter
            option you will need to instruct your model to monitize the correct columns.
            See the README for details.
          MSG

          [:amount, :currency].each do |attribute|
            column_present, *opts = OptionsExtractor.extract attribute, table_name, accessor, options
            add_column *opts if column_present
          end
        end

        def remove_money(table_name, accessor, options={})
          MoneyRails.deprecator.warn(<<-MSG.squish)
            `#t.remove_money` is deprecated and will be removed in money-rails version 2. Either
            explicity name your money and currency columns `COLUMN_NAME_cents` and
            `COLUMN_NAME_currency` or pick a different name. If you pick the latter
            option you will need to instruct your model to monitize the correct columns.
            See the README for details.
          MSG

          [:amount, :currency].each do |attribute|
            column_present, table_name, column_name, _, _ =  OptionsExtractor.extract attribute, table_name, accessor, options
            remove_column table_name, column_name if column_present
          end
        end
      end
    end
  end
end
