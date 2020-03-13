module MoneyRails
  module ActiveRecord
    module MigrationExtensions
      module SchemaStatements
        def add_money(table_name, accessor, options={})
          add_monetize(table_name, accessor, options)
        end

        def remove_money(table_name, accessor, options={})
          remove_monetize(table_name, accessor, options)
        end
      end
    end
  end
end
