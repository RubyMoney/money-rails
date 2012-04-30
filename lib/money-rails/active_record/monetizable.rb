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

          # Model currency field name
          model_currency_name = options[:with_model_currency] ||
            options[:model_currency] || "currency"

          # Override Model and default currency
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

          class_eval do
            composed_of name.to_sym,
              :class_name => "Money",
              :mapping => [[subunit_name, "cents"], [model_currency_name, "currency_as_string"]],
              :constructor => Proc.new { |cents, currency|
              Money.new(cents || 0, field_currency_name || currency ||
                        Money.default_currency)
            },
              :converter => Proc.new { |value|
              if  value.respond_to?(:to_money)
                if field_currency_name
                  value.to_money(field_currency_name)
                else
                  value.to_money
                end
              else
                raise(ArgumentError, "Can't convert #{value.class} to Money")
              end
            }
          end

          # Include numericality validation if needed
          if MoneyRails.include_validations
            class_eval do
              validates_numericality_of subunit_name
            end
          end
        end
      end
    end
  end
end
