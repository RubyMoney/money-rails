require 'active_support/concern'
require 'active_support/core_ext/array/extract_options'
require 'active_support/deprecation/reporting'
require 'money-rails/active_record/model_extensions/monetizable_attribute'
require 'money-rails/active_record/model_extensions/currency_finder'
require 'money-rails/active_record/model_extensions/attribute_writer'
require 'money-rails/active_record/model_extensions/attribute_reader'

module MoneyRails
  module ActiveRecord
    module Monetizable
      class ReadOnlyCurrencyException < StandardError; end
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
          fields.each { |field| define_methods_for(field, options) }
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

        def define_methods_for(field, options)
          attribute = ModelExtensions::MonetizableAttribute.new(field, options)

          show_deprecation if attribute.deprecated?

          # Create a reverse mapping of the monetized attributes
          track_monetized_attribute attribute

          if attribute.validation_enabled?
            add_numeric_validations(attribute)
            define_subunit_writer_method(attribute)
          end

          define_reader_method(attribute)
          define_writer_method(attribute)

          define_currency_method(attribute)

          attr_reader "#{attribute.name}_money_before_type_cast"

          # Hook to ensure the reset of before_type_cast attr
          # TODO: think of a better way to avoid this
          after_save do
            instance_variable_set "@#{attribute.name}_money_before_type_cast", nil
          end
        end

        def define_currency_method(attribute)
          define_method "currency_for_#{attribute.name}" do
            ModelExtensions::CurrencyFinder.new(self, attribute).call
          end
        end

        def define_subunit_writer_method(attribute)
          # Ensure that the before_type_cast value is cleared when setting
          # the subunit value directly
          define_method "#{attribute.subunit_name}=" do |value|
            instance_variable_set "@#{attribute.name}_money_before_type_cast", nil
            write_attribute(attribute.subunit_name, value)
          end
        end

        def define_writer_method(attribute)
          name = attribute.name
          define_method "#{name}=" do |value|
            ModelExtensions::AttributeWriter.new(self, attribute, value).call
          end
        end

        def define_reader_method(attribute)
          name = attribute.name
          define_method name do |*args|
            ModelExtensions::AttributeReader.new(self, attribute, args).call
          end
        end

        def track_monetized_attribute(attribute)
          @monetized_attributes ||= {}.with_indifferent_access

          if @monetized_attributes[attribute.name].present?
            raise ArgumentError, "#{self} already has a monetized attribute called '#{attribute.name}'"
          end

          @monetized_attributes[attribute.name] = attribute.subunit_name
        end

        def show_deprecation
          ActiveSupport::Deprecation.warn("You are using the old " \
                                          "argument keys of the monetize command! Instead use :as, " \
                                          ":with_currency or :with_model_currency")
        end

        def add_subunit_validation(subunit_name, options)
          # This is a validation for the subunit
          if (subunit_numericality = options.fetch(:subunit_numericality, true))
            validates subunit_name, {
              :allow_nil => options[:allow_nil],
              :numericality => subunit_numericality
            }
          end
        end

        def add_unit_validation(name, options)
          # Allow only Money objects or Numeric values!
          if (numericality = options.fetch(:numericality, true))
            validates name.to_sym, {
              :allow_nil => options[:allow_nil],
              'money_rails/active_model/money' => numericality
            }
          end
        end

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
        #       :message => "must be greater than zero and less than $100"
        #     }
        #
        # To disable validation entirely, use :disable_validation, E.g:
        #   monetize :price_in_a_range_cents, :disable_validation => true
        def add_numeric_validations(attribute)
          add_subunit_validation(attribute.subunit_name, attribute.options)
          add_unit_validation(attribute.name, attribute.options)
        end
      end
    end
  end
end
