module MoneyRails
  module ActiveModel
    class MoneyValidator < ::ActiveModel::EachValidator
      def validate_each(record, attr, value)

        # WARNING: Currently this is only defined in ActiveRecord extension!
        before_type_cast = "#{attr}_before_type_cast"
        raw_value = record.send(before_type_cast) if record.respond_to?(before_type_cast.to_sym)

        # Skip it if raw_value is already a Money object
        return if raw_value.is_a?(Money)

        raw_value ||= value

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
