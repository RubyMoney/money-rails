module MoneyRails
  module ActiveRecord
    module ModelExtensions
      class AttributeWriter

        attr_accessor :model, :name, :instance_currency_name, :value,
          :options, :attribute

        def initialize(model, attribute, value)
          @model = model
          @name = attribute.name
          @instance_currency_name = attribute.instance_currency_name
          @options = attribute.options
          @value = value
          @attribute = attribute
        end

        def call
          # Lets keep the before_type_cast value
          model.instance_variable_set "@#{name}_money_before_type_cast", value
          update_cents
          update_currency

          # Save and return the new Money object
          model.instance_variable_set "@#{name}", money
        end

        private

        def update_currency
          money_currency = money.try(:currency)
          # Update currency iso value if there is an instance currency attribute
          if instance_currency_attribute?(money_currency)
            model.public_send("#{instance_currency_name}=", money_currency.try(:iso_code))
          else
            current_currency = model.public_send("currency_for_#{name}")
            if raise_readonly_exception?(current_currency, money_currency)
              raise_readonly_exception(current_currency, money_currency)
              return nil
            end
          end
        end

        def raise_readonly_exception?(current_currency, money_currency)
          money_currency && current_currency != money_currency.id &&
              MoneyRails.raise_error_on_money_parsing
        end

        def raise_readonly_exception(current_currency, money_currency)
          message = "Can't change readonly currency '#{current_currency}' to '#{money_currency}' for field '#{name}'"
          raise MoneyRails::ActiveRecord::Monetizable::ReadOnlyCurrencyException.new(message)
        end

        def instance_currency_attribute?(money_currency)
          instance_currency_name.present? &&
            model.respond_to?("#{instance_currency_name}=") && money_currency
        end

        def update_cents
          cents = money.try(:cents)

          if !attribute.validation_enabled?
            # We haven't defined our own subunit writer, so we can invoke
            # the regular writer, which works with store_accessors
            model.public_send("#{attribute.subunit_name}=", cents)
          elsif model.class.respond_to?(:attribute_aliases) &&
            model.class.attribute_aliases.key?(attribute.subunit_name)
            # If the attribute is aliased, make sure we write to the original
            # attribute name or an error will be raised.
            # (Note: 'attribute_aliases' doesn't exist in Rails 3.x, so we
            # can't tell if the attribute was aliased.)
            original_name = model.class.attribute_aliases[attribute.subunit_name.to_s]
            model.send(:write_attribute, original_name, cents)
          else
            model.send(:write_attribute, attribute.subunit_name, cents)
          end
        end

        def money
          # Use nil or get a Money object
          if options[:allow_nil] && value.blank?
            money = nil
          else
            if value.is_a?(Money)
              money = value
            else
              begin
                money = value.to_money(model.public_send("currency_for_#{name}"))
              rescue NoMethodError
                return nil
              rescue ArgumentError
                raise if MoneyRails.raise_error_on_money_parsing
                return nil
              rescue Money::Currency::UnknownCurrency
                raise if MoneyRails.raise_error_on_money_parsing
                return nil
              end
            end
          end
        end
      end
    end
  end
end
