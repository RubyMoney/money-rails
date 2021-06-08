module MoneyRails
  module ActiveRecord
    module MigrationExtensions
      class OptionsExtractor
        def self.extract(attribute, table_name, accessor, options = {})
          # Placing the default_for_both_columns first allows for 
          # the options of the specific column to take precendence when they are passed. 
          default_for_both_columns = {}
          default_for_both_columns =default_for_both_columns.merge(null: options[:null]) if options.has_key?(:null) 

          default = MoneyRails::Configuration.send("#{attribute}_column").merge(options[attribute] || default_for_both_columns)

          default[:column_name] ||= [default[:prefix], accessor, default[:postfix]].join
          default[:table_name] = table_name

          excluded_keys = [:amount, :currency, :type, :prefix, :postfix, :present, :column_name, :table_name]
          default[:options] = default.except(*excluded_keys)

          default.slice(:present, :table_name, :column_name, :type, :options).values
        end
      end
    end
  end
end
