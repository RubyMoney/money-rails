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
          instance_currency_name = instance_currency_name.to_s

          # This attribute allows per column currency values
          # Overrides row and default currency
          field_currency_name = options[:with_currency] ||
            options[:field_currency] || nil

          name = options[:as] || options[:target_name] || nil

          # Form target name for the money backed ActiveModel field:
          # if a target name is provided then use it
          # if there is a "_{column.postfix}" suffix then just remove it to create the target name
          # if none of the previous is the case then use a default suffix
          if name
            name = name.to_s
          elsif subunit_name =~ /#{MoneyRails::Configuration.amount_column[:postfix]}$/
            name = subunit_name.sub(/#{MoneyRails::Configuration.amount_column[:postfix]}$/, "")
          else
            # FIXME: provide a better default
            name = [subunit_name, "money"].join("_")
          end

          # Create a reverse mapping of the monetized attributes
          @monetized_attributes ||= {}
          @monetized_attributes[name.to_sym] = subunit_name
          class << self
            def monetized_attributes
              @monetized_attributes || superclass.monetized_attributes
            end
          end unless respond_to? :monetized_attributes

          # Include numericality validations if needed.
          # There are two validation options:
          #
          # 1. Subunit field validation (e.g. cents should be > 100)
          # 2. Money field validation (e.g. euros should be > 10)
          #
          # All the options which are available for Rails numericality
          # validation, are also available for both types.
          # E.g. 
          #   monetize :price_in_a_range_cents, :allow_nil => true,
          #     :subunit_numericality => {
          #       :greater_than_or_equal_to => 0,
          #       :less_than_or_equal_to => 10000,
          #     },
          #     :numericality => {
          #       :greater_than_or_equal_to => 0,
          #       :less_than_or_equal_to => 100,
          #       :message => "Must be greater than zero and less than $100"
          #     }
          #
          if MoneyRails.include_validations

            subunit_validation_options =
              unless options.has_key? :subunit_numericality
                true
              else
                options[:subunit_numericality]
              end

            money_validation_options =
              unless options.has_key? :numericality
                true
              else
                options[:numericality]
              end

            # This is a validation for the subunit
            validates subunit_name, {
              :allow_nil => options[:allow_nil],
              :numericality => subunit_validation_options
            }

            # Allow only Money objects or Numeric values!
            validates name.to_sym, {
              :allow_nil => options[:allow_nil],
              'money_rails/active_model/money' => money_validation_options
            }
          end

          define_method name do |*args|

            # Get the cents
            amount = send(subunit_name, *args)

            # Get the currency object
            attr_currency = send("currency_for_#{name}")

            # Get the cached value
            memoized = instance_variable_get("@#{name}")

            # Dont create a new Money instance if the values haven't been changed.
            return memoized if memoized && memoized.cents == amount &&
              memoized.currency == attr_currency

            # If amount is NOT nil (or empty string) load the amount in a Money
            amount = Money.new(amount, attr_currency) unless amount.blank?

            # Cache and return the value (it may be nil)
            instance_variable_set "@#{name}", amount
          end

          define_method "#{name}=" do |value|

            # Lets keep the before_type_cast value
            instance_variable_set "@#{name}_money_before_type_cast", value

            # Use nil or get a Money object
            if options[:allow_nil] && value.blank?
              money = nil
            else
              begin
                money = value.is_a?(Money) ? value : value.to_money(send("currency_for_#{name}"))
              rescue NoMethodError
                return nil
              end
            end

            # Update cents
            send("#{subunit_name}=", money.try(:cents))

            # Update currency iso value if there is an instance currency attribute
            if self.respond_to?("#{instance_currency_name}=")
              send("#{instance_currency_name}=", money.try(:currency).try(:iso_code))
            elsif self.respond_to?("#{name}#{MoneyRails::Configuration.currency_column[:postfix]}=")
              send("#{name}#{MoneyRails::Configuration.currency_column[:postfix]}=", money.try(:currency).try(:iso_code))
            end


            # Save and return the new Money object
            instance_variable_set "@#{name}", money
          end

          define_method "currency_for_#{name}" do
            if self.respond_to?(instance_currency_name) && send(instance_currency_name).present? &&
                Money::Currency.find(send(instance_currency_name))
              Money::Currency.find(send(instance_currency_name))
            elsif field_currency_name
              Money::Currency.find(field_currency_name)
            elsif self.class.respond_to?(:currency)
              self.class.currency
            elsif self.respond_to?("#{name}#{MoneyRails::Configuration.currency_column[:postfix]}")
              Money::Currency.find(self.send("#{name}#{MoneyRails::Configuration.currency_column[:postfix]}"))
            else
              Money.default_currency
            end
          end

          define_method "#{name}_money_before_type_cast" do
            instance_variable_get "@#{name}_money_before_type_cast"
          end

          # Hook to ensure the reset of before_type_cast attr
          # TODO: think of a better way to avoid this
          after_save do
            instance_variable_set "@#{name}_money_before_type_cast", nil
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
