module MoneyRails
  module ActiveRecord
    module MigrationExtensions
      module Table
        def money(accessor, options={})
          MoneyRails.deprecator.warn(<<-MSG.squish)
            `#t.money` is deprecated and will be removed in money-rails version 2. Either
            explicity name your money and currency columns `COLUMN_NAME_cents` and
            `COLUMN_NAME_currency` or pick a different name. If you pick the latter
            option you will need to instruct your model to monitize the correct columns.
            See the README for details.
          MSG

          [:amount, :currency].each do |attribute|
            column_present, _, *opts = OptionsExtractor.extract attribute, :no_table, accessor, options
            column *opts if column_present
          end
        end

        def remove_money(accessor, options={})
          MoneyRails.deprecator.warn(<<-MSG.squish)
            `#t.remove_money` is deprecated and will be removed in money-rails version 2. Either
            explicity name your money and currency columns `COLUMN_NAME_cents` and
            `COLUMN_NAME_currency` or pick a different name. If you pick the latter
            option you will need to instruct your model to monitize the correct columns.
            See the README for details.
          MSG

          [:amount, :currency].each do |attribute|
            column_present, _, column_name, _, _ =  OptionsExtractor.extract attribute, :no_table, accessor, options
            remove column_name if column_present
          end
        end
      end
    end
  end
end
