# frozen_string_literal: true

module MoneyRails
  module ActiveRecord
    module MigrationExtensions
      class OptionsExtractor
        def self.extract(attribute, table_name, accessor, options = {})
          # A top-level `null` option applies to both columns; per-attribute
          # `amount`/`currency` options take precedence over it.
          default_for_both_columns = { null: options[:null] }.compact
          default = MoneyRails::Configuration.send("#{attribute}_column")
                                             .merge(default_for_both_columns, options[attribute] || {})

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
