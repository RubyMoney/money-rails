module MoneyRails
  module ActiveRecord
    module ModelExtensions
        class AttributeReader
          attr_accessor :model, :name, :args, :attribute
          def initialize(model, attribute, args)
            @model = model
            @name = attribute.name
            @args = args
            @attribute = attribute
          end

          def call
            # Dont create a new Money instance if the values haven't been changed.
            result = has_changed? ? memoized_value : change_amount
            redefine_singletons(result)
            result
          end

          private

          def change_amount
            # If amount is NOT nil (or empty string) load the amount in a Money
            new_amount = Money.new(old_amount, attr_currency) unless old_amount.blank?

            # Cache the value (it may be nil)
            model.instance_variable_set "@#{name}", new_amount
          end

          def old_amount
            @old_amount ||= model.public_send(attribute.subunit_name, *args)
          end

          def has_changed?
            memoized_value && memoized_value.cents == old_amount &&
              memoized_value.currency == attr_currency
          end

          def memoized_value
            @memoized ||= model.instance_variable_get("@#{name}")
          end

          def attr_currency
            @attr_currency ||= model.public_send("currency_for_#{name}")
          end

          def redefine_singletons(result)
            if MoneyRails::Configuration.preserve_user_input
              value_before_type_cast = model.instance_variable_get "@#{name}_money_before_type_cast"
              unless model.errors[name.to_sym].blank?
                result.define_singleton_method(:to_s) { value_before_type_cast }
                result.define_singleton_method(:format) { |_| value_before_type_cast }
              end
            end
          end
        end
    end
  end
end
