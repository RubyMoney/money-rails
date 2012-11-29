module MoneyRails
  module ActiveRecord
    module MigrationExtensions
      module SchemaStatements
        def add_money(table_name, accessor, options={})
          [:amount, :currency].each do |attribute|
            column_present, *opts = OptionsExtractor.extract attribute, table_name, accessor, options
            add_column *opts if column_present
          end
        end

        def remove_money(table_name, accessor, options={})
          [:amount, :currency].each do |attribute|
            column_present, table_name, _, column_name, _ =  OptionsExtractor.extract attribute, table_name, accessor, options
            remove_column table_name, column_name if column_present
          end
        end
      end
    end
  end
end
