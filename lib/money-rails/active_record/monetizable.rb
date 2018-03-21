require 'active_support/concern'
require 'active_support/core_ext/array/extract_options'
require 'active_support/deprecation/reporting'

module MoneyRails
  module ActiveRecord
    module Monetizable
      class ReadOnlyCurrencyException < MoneyRails::Error; end
      extend ActiveSupport::Concern

      module ClassMethods
        def monetized_attributes
          monetized_attributes = @monetized_attributes || {}

          if superclass.respond_to?(:monetized_attributes)
            monetized_attributes.merge(superclass.monetized_attributes)
          else
            monetized_attributes
          end
        end

        def monetize(*fields)
          options = fields.extract_options!

          fields.each do |field|
            # Stringify model field name
            subunit_name = field.to_s

            if options[:field_currency] || options[:target_name] || options[:model_currency]
              ActiveSupport::Deprecation.warn("You are using the old " \
                                              "argument keys of the monetize command! Instead use :as, " \
                                              ":with_currency or :with_model_currency")
            end

            name = options[:as] || options[:target_name] || nil

            # Form target name for the money backed ActiveModel field:
            # if a target name is provided then use it
            # if there is a "{column.postfix}" suffix then just remove it to create the target name
            # if none of the previous is the case then use a default suffix
            if name
              name = name.to_s

              # Check if the options[:as] parameter is not the same as subunit_name
              # which would result in stack overflow
              if name == subunit_name
                raise ArgumentError, "monetizable attribute name cannot be the same as options[:as] parameter"
              end

            elsif subunit_name =~ /#{MoneyRails::Configuration.amount_column[:postfix]}$/
              name = subunit_name.sub(/#{MoneyRails::Configuration.amount_column[:postfix]}$/, "")
            else
              raise ArgumentError, "Unable to infer the name of the monetizable attribute for '#{subunit_name}'. " \
                                   "Expected amount column postfix is '#{MoneyRails::Configuration.amount_column[:postfix]}'. " \
                                   "Use :as option to explicitly specify the name or change the amount column postfix in the initializer."
            end

            # Optional accessor to be run on an instance to detect currency
            instance_currency_name = options[:with_model_currency] ||
              options[:model_currency] ||
              MoneyRails::Configuration.currency_column[:column_name]

            # Infer currency column from name and postfix
            if !instance_currency_name && MoneyRails::Configuration.currency_column[:postfix].present?
              instance_currency_name = "#{name}#{MoneyRails::Configuration.currency_column[:postfix]}"
            end

            instance_currency_name = instance_currency_name && instance_currency_name.to_s

            # This attribute allows per column currency values
            # Overrides row and default currency
            field_currency_name = options[:with_currency] ||
              options[:field_currency] || nil

            # Create a reverse mapping of the monetized attributes
            track_monetized_attribute name, subunit_name

            # Include numericality validations if needed.
            # There are two validation options:
            #
            # 1. Subunit field validation (e.g. cents should be > 100)
            # 2. Money field validation (e.g. euros should be > 10)
            #
            # All the options which are available for Rails numericality
            # validation, are also available for both types.
            # E.g.
            #   monetize :price_in_a_range_cents, allow_nil: true,
            #     subunit_numericality: {
            #       greater_than_or_equal_to: 0,
            #       less_than_or_equal_to: 10000,
            #     },
            #     numericality: {
            #       greater_than_or_equal_to: 0,
            #       less_than_or_equal_to: 100,
            #       message: "must be greater than zero and less than $100"
            #     }
            #
            # To disable validation entirely, use :disable_validation, E.g:
            #   monetize :price_in_a_range_cents, disable_validation: true
            if (validation_enabled = MoneyRails.include_validations && !options[:disable_validation])

              # This is a validation for the subunit
              if (subunit_numericality = options.fetch(:subunit_numericality, true))
                validates subunit_name, {
                  allow_nil: options[:allow_nil],
                  numericality: subunit_numericality
                }
              end

              # Allow only Money objects or Numeric values!
              if (numericality = options.fetch(:numericality, true))
                validates name.to_sym, {
                  allow_nil: options[:allow_nil],
                  'money_rails/active_model/money' => numericality
                }
              end
            end


            # Getter for monetized attribute
            define_method name do |*args|
              read_monetized name, subunit_name, options, *args
            end

            # Setter for monetized attribute
            define_method "#{name}=" do |value|
              write_monetized name, subunit_name, value, validation_enabled, instance_currency_name, options
            end

            if validation_enabled
              # Ensure that the before_type_cast value is cleared when setting
              # the subunit value directly
              define_method "#{subunit_name}=" do |value|
                instance_variable_set "@#{name}_money_before_type_cast", nil
                write_attribute(subunit_name, value)
              end
            end

            # Currency getter
            define_method "currency_for_#{name}" do
              currency_for name, instance_currency_name, field_currency_name
            end

            attr_reader "#{name}_money_before_type_cast"

            # Hook to ensure the reset of before_type_cast attr
            # TODO: think of a better way to avoid this
            after_save do
              instance_variable_set "@#{name}_money_before_type_cast", nil
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

        private

        def track_monetized_attribute(name, value)
          @monetized_attributes ||= {}.with_indifferent_access

          if @monetized_attributes[name].present?
            raise ArgumentError, "#{self} already has a monetized attribute called '#{name}'"
          end

          @monetized_attributes[name] = value
        end
      end

      def read_monetized(name, subunit_name, options = {}, *args)
        # Get the cents
        amount = public_send(subunit_name, *args)

        return if amount.nil? && options[:allow_nil]
        # Get the currency object
        attr_currency = public_send("currency_for_#{name}")

        # Get the cached value
        memoized = instance_variable_get("@#{name}")

        # Dont create a new Money instance if the values haven't been changed.
        if memoized && memoized.cents == amount
          if memoized.currency == attr_currency
            result = memoized
          else
            memoized_amount = memoized.amount.to_money(attr_currency)
            write_attribute subunit_name, memoized_amount.cents
            # Cache the value (it may be nil)
            result = instance_variable_set("@#{name}", memoized_amount)
          end
        elsif amount.present?
          # If amount is NOT nil (or empty string) load the amount in a Money
          amount = Money.new(amount, attr_currency)

          # Cache the value (it may be nil)
          result = instance_variable_set("@#{name}", amount)
        end

        if MoneyRails::Configuration.preserve_user_input
          value_before_type_cast = instance_variable_get "@#{name}_money_before_type_cast"
          if errors[name.to_sym].present?
            result.define_singleton_method(:to_s) { value_before_type_cast }
            result.define_singleton_method(:format) { |_| value_before_type_cast }
          end
        end

        result
      end

      def write_monetized(name, subunit_name, value, validation_enabled, instance_currency_name, options)
        # Keep before_type_cast value as a reference to original input
        instance_variable_set "@#{name}_money_before_type_cast", value

        # Use nil or get a Money object
        if options[:allow_nil] && value.blank?
          money = nil
        else
          if value.is_a?(Money)
            money = value
          else
            begin
              money = value.to_money(public_send("currency_for_#{name}"))
            rescue NoMethodError
              return nil
            rescue Money::Currency::UnknownCurrency, Monetize::ParseError => e
              raise MoneyRails::Error, e.message if MoneyRails.raise_error_on_money_parsing
              return nil
            end
          end
        end

        # Update cents
        if !validation_enabled
          # We haven't defined our own subunit writer, so we can invoke
          # the regular writer, which works with store_accessors
          public_send("#{subunit_name}=", money.try(:cents))
        elsif self.class.respond_to?(:attribute_aliases) &&
            self.class.attribute_aliases.key?(subunit_name)
          # If the attribute is aliased, make sure we write to the original
          # attribute name or an error will be raised.
          # (Note: 'attribute_aliases' doesn't exist in Rails 3.x, so we
          # can't tell if the attribute was aliased.)
          original_name = self.class.attribute_aliases[subunit_name.to_s]
          write_attribute(original_name, money.try(:cents))
        else
          write_attribute(subunit_name, money.try(:cents))
        end

        if money_currency = money.try(:currency)
          # Update currency iso value if there is an instance currency attribute
          if instance_currency_name.present? && respond_to?("#{instance_currency_name}=")
            public_send("#{instance_currency_name}=", money_currency.iso_code)
          else
            current_currency = public_send("currency_for_#{name}")
            if current_currency != money_currency.id
              raise ReadOnlyCurrencyException.new("Can't change readonly currency '#{current_currency}' to '#{money_currency}' for field '#{name}'") if MoneyRails.raise_error_on_money_parsing
              return nil
            end
          end
        end

        # Save and return the new Money object
        instance_variable_set "@#{name}", money
      end

      def currency_for(name, instance_currency_name, field_currency_name)
        if instance_currency_name.present? && respond_to?(instance_currency_name) &&
            Money::Currency.find(public_send(instance_currency_name))

          Money::Currency.find(public_send(instance_currency_name))
        elsif field_currency_name.respond_to?(:call)
          Money::Currency.find(field_currency_name.call(self))
        elsif field_currency_name
          Money::Currency.find(field_currency_name)
        elsif self.class.respond_to?(:currency)
          self.class.currency
        else
          Money.default_currency
        end
      end
    end
  end
end
