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

          # Optional accessor to be run on an instance to detect currency 
          instance_currency_name = options[:with_model_currency] ||
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

          # Include numericality validation if needed
          validates_numericality_of subunit_name, :allow_nil => options[:allow_nil] if MoneyRails.include_validations

          define_method name do
            amount = send(subunit_name)
            attr_currency = send("currency_for_#{name}")

            # Dont create a new Money instance if the values haven't changed
            memoized = instance_variable_get("@#{name}")
            return memoized if memoized && memoized.cents == amount &&
              memoized.currency == attr_currency

            amount = Money.new(amount, attr_currency) unless amount.blank?

            instance_variable_set "@#{name}", amount
          end

          define_method "#{name}=" do |value|
            if options[:allow_nil] && value.blank?
              money = nil
            else
              money = value.is_a?(Money) ? value : value.to_money(send("currency_for_#{name}"))
            end

            send("#{subunit_name}=", money.try(:cents))
            send("#{instance_currency_name}=", money.try(:currency)) if self.respond_to?("#{instance_currency_name}=")

            instance_variable_set "@#{name}", money
          end

          define_method "currency_for_#{name}" do
            if self.respond_to?(instance_currency_name) && send(instance_currency_name).present? 
              Money::Currency.find(send(instance_currency_name))
            elsif field_currency_name
              Money::Currency.find(field_currency_name)
            elsif self.class.respond_to?(:currency)
              self.class.currency
            else
              Money.default_currency
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
