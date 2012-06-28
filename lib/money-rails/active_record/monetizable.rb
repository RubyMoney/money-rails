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

          has_currency_table_column = self.attribute_names.include? model_currency_name
          
          raise(ArgumentError, ":with_currency should not be used with tables" \
                  " which contain a column for currency values") if has_currency_table_column && field_currency_name

          # Include numericality validation if needed
          validates_numericality_of subunit_name, :allow_nil => options[:allow_nil] if MoneyRails.include_validations
            
          define_method name do
            amount = read_attribute(subunit_name)
            amount = Money.new(amount, send("currency_for_#{name}")) unless amount.blank? 

            instance_variable_set "@#{name}", amount
          end

          define_method "#{name}=" do |value|
            if options[:allow_nil] && value.blank?
              write_attribute(subunit_name, nil)
              write_attribute(:currency, nil) if has_currency_table_column
              instance_variable_set "@#{name}", nil
              return
            end
              
            if has_currency_table_column 
              raise(ArgumentError, "Only Money objects are allowed for assignment") unless value.kind_of?(Money)
              money = value
              write_attribute(model_currency_name, money.currency.iso_code)
            else
              raise(ArgumentError, "Can't convert #{value.class} to Money") unless value.respond_to?(:to_money) 
              money = value.to_money(send("currency_for_#{name}"))
            end

            instance_variable_set "@#{name}", money

            write_attribute(subunit_name, money.cents)
          end

          define_method "currency_for_#{name}" do
            (has_currency_table_column ? read_attribute(:currency) : field_currency_name) || 
              (self.class.respond_to?(:currency) && self.class.currency) || Money.default_currency
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
