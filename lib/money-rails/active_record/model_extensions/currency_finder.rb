module MoneyRails
  module ActiveRecord
    module ModelExtensions
      class CurrencyFinder
        attr_accessor :model, :name, :instance_currency_name,
          :field_currency_name, :instance_currency_name_with_postfix

        def initialize(model, attribute)
          @model = model
          @name = attribute.name
          @instance_currency_name = attribute.instance_currency_name
          @field_currency_name = attribute.field_currency_name
          if MoneyRails::Configuration.currency_column[:postfix].present?
            @instance_currency_name_with_postfix = "#{name}#{MoneyRails::Configuration.currency_column[:postfix]}"
          end
        end

        def call
          instance_currency || field_currency ||
            instance_currency_with_postfix ||
            class_currency || default_currency
        end

        private

        def default_currency
          Money.default_currency
        end

        def class_currency
          if model.class.respond_to?(:currency)
            model.class.currency
          end
        end

        def instance_currency_with_postfix
          if instance_currency_name_with_postfix.present? &&
              model.respond_to?(instance_currency_name_with_postfix) &&
              Money::Currency.find(model.public_send(instance_currency_name_with_postfix))

            Money::Currency.find(model.public_send(instance_currency_name_with_postfix))
          end
        end

        def field_currency
          if field_currency_name.respond_to?(:call)
            Money::Currency.find(field_currency_name.call(model))
          elsif field_currency_name
            Money::Currency.find(field_currency_name)
          end
        end

        def instance_currency
          if instance_currency_name.present? && model.respond_to?(instance_currency_name) &&
              Money::Currency.find(model.public_send(instance_currency_name))

            Money::Currency.find(model.public_send(instance_currency_name))
          end
        end
      end
    end
  end
end
