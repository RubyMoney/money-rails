module MoneyRails
  module ActiveRecord
    module MigrationExtensions
      module SchemaStatements
        def add_monetize(table_name, accessor, options = {})
          [:amount, :currency].each do |attribute|
            column_present, table_name, column_name, column_type, opts = OptionsExtractor.extract attribute, table_name, accessor, options
            add_column(table_name, column_name, column_type, **opts) if column_present
          end
        end

        def remove_monetize(table_name, accessor, options = {})
          [:amount, :currency].each do |attribute|
            column_present, table_name, column_name, type = OptionsExtractor.extract attribute, table_name, accessor, options
            remove_column table_name, column_name, type if column_present
          end
        end
      end
    end
  end
end
