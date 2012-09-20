module MoneyRails
  module ActiveModel
    class MoneyValidator < ::ActiveModel::EachValidator
      def validate_each(record, attr, value)

        # If subunit is not set then no need to validate as it is an
        # indicator that no assignment has been done onto the virtual
        # money field.
        subunit_attr = record.class.monetized_attributes[attr.to_sym]
        return unless record.changed_attributes.keys.include? subunit_attr

        # WARNING: Currently this is only defined in ActiveRecord extension!
        before_type_cast = "#{attr}_before_type_cast"
        raw_value = record.send(before_type_cast) if record.respond_to?(before_type_cast.to_sym)

        # Skip it if raw_value is already a Money object
        return if raw_value.is_a?(Money) || raw_value.nil?

        # Extracted from activemodel's protected parse_raw_value_as_a_number
        parsed_value = case raw_value
                       when /\A0[xX]/
                         nil
                       else
                         begin
                           Kernel.Float(raw_value)
                         rescue ArgumentError, TypeError
                           nil
                         end
                       end

        unless parsed_value
          record.errors.add(attr, :not_a_number)
        end
      end
    end
  end
end
