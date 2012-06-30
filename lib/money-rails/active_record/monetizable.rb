require 'active_support/concern'
require 'active_support/core_ext/array/extract_options'
require 'active_support/deprecation/reporting'

module MoneyRails
  module ActiveRecord
    module Monetizable
      extend ActiveSupport::Concern

      module ClassMethods
        def monetize(field, *args)
          options = args.extract_options!

          # Stringify model field name
          subunit_name = field.to_s

          if options[:field_currency] || options[:target_name] ||
            options[:model_currency]
            ActiveSupport::Deprecation.warn("You are using the old " \
              "argument keys of monetize command! Instead use :as, " \
              ":with_currency or :with_model_currency")
          end

          # Optional table column which holds currency iso_codes
          # It allows per row currency values
          # Overrides default currency
          model_currency_name = options[:with_model_currency] ||
            options[:model_currency] || "currency"

          # This attribute allows per column currency values
          # Overrides row and default currency
          field_currency_name = options[:with_currency] ||
            options[:field_currency] || nil

          name = options[:as] || options[:target_name] || nil

          # Form target name for the money backed ActiveModel field:
          # if a target name is provided then use it
          # if there is a "_cents" suffix then just remove it to create the target name
          # if none of the previous is the case then use a default suffix
          if name
            name = name.to_s
          elsif subunit_name =~ /_cents$/
            name = subunit_name.sub(/_cents$/, "")
          else
            # FIXME: provide a better default
            name = subunit_name << "_money"
          end

          has_currency_table_column = self.column_names.include? model_currency_name

          if has_currency_table_column
            raise(ArgumentError, ":with_currency should not be used with tables" \
                  " which contain a column for currency values") if field_currency_name

            mappings = [[subunit_name, "cents"], [model_currency_name, "currency_as_string"]]
            constructor = Proc.new { |cents, currency|
              Money.new(cents, currency || self.respond_to?(:currency) &&
                        self.currency || Money.default_currency)
            }
            converter = Proc.new { |value|
              raise(ArgumentError, "Only Money objects are allowed for assignment")
            }
          else
            mappings = [[subunit_name, "cents"]]
            constructor = Proc.new { |cents|
              Money.new(cents, field_currency_name || self.respond_to?(:currency) &&
                        self.currency || Money.default_currency)
            }
            converter = Proc.new { |value|
              if options[:allow_nil] && value.blank?
                nil
              elsif value.respond_to?(:to_money)
                value.to_money(field_currency_name || self.respond_to?(:currency) &&
                              self.currency || Money.default_currency)
              else
                raise(ArgumentError, "Can't convert #{value.class} to Money")
              end
            }
          end

          class_eval do
            composed_of name.to_sym,
              :class_name => "Money",
              :mapping => mappings,
              :constructor => constructor,
              :converter => converter,
              :allow_nil => options[:allow_nil]
          end

          if options[:allow_nil]
            class_eval do
              # Fixes issue with composed_of that breaks on blank params
              # TODO: This should be removed when we will only support rails >=4.0
              define_method "#{name}_with_blank_support=" do |value|
                value = nil if value.blank?
                send "#{name}_without_blank_support=", value
              end
              alias_method_chain "#{name}=", :blank_support
            end
          end

          # Include numericality validation if needed
          if MoneyRails.include_validations
            class_eval do
              validates_numericality_of subunit_name, :allow_nil => options[:allow_nil]
            end
          end
        end

        def register_currency(currency_name)
          # Lookup the given currency_name and raise exception if
          # no currency is found
          currency_object = Money::Currency.find currency_name
          raise(ArgumentError, "Can't find #{currency_name} currency code") unless currency_object

          class_eval do
            @currency = currency_object
            class << self
              attr_reader :currency
            end
          end
        end
      end
    end
  end
end
