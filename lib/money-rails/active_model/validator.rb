module MoneyRails
  module ActiveModel
    class MoneyValidator < ::ActiveModel::Validations::NumericalityValidator
      def validate_each(record, attr, value)
        reset_memoized_variables!
        @record = record
        @attr = attr

        subunit_attr = @record.class.monetized_attributes[@attr.to_s]

        # WARNING: Currently this is only defined in ActiveRecord extension!
        before_type_cast = :"#{@attr}_money_before_type_cast"
        @raw_value = @record.try(before_type_cast)

        # If raw value is nil and changed subunit is nil, then
        # nil is a assigned value, else we should treat the
        # subunit value as the one assigned.
        if @raw_value.nil? && @record.public_send(subunit_attr)
          subunit_value = @record.public_send(subunit_attr)
          @raw_value = subunit_value.to_f / currency.subunit_to_unit
        end

        return if options[:allow_nil] && @raw_value.nil?

        # Skip normalization for Numeric values
        # which can directly be handled by NumericalityValidator
        if raw_value_is_non_numeric
          # remove currency symbol, and negative sign
          @raw_value = @raw_value.to_s.strip.gsub(symbol, "")

          add_error and return if value_has_too_many_decimal_points
          add_error if invalid_thousands_separation

        end

        normalize_raw_value!
        super(@record, @attr, @raw_value)
      end

      private

      def reset_memoized_variables!
        [:currency, :decimal_mark, :thousands_separator, :symbol,
          :abs_raw_value, :decimal_pieces, :pieces_array].each do |var_name|
          ivar_name = :"@_#{var_name}"
          remove_instance_variable(ivar_name) if instance_variable_get(ivar_name)
        end
      end

      def currency
        @_currency ||= @record.public_send("currency_for_#{@attr}")
      end

      def decimal_mark
        @_decimal_mark ||= I18n.t('number.currency.format.separator', default: currency.decimal_mark)
      end

      def thousands_separator
        @_thousands_separator ||= I18n.t('number.currency.format.delimiter', default: currency.thousands_separator)
      end

      def symbol
        @_symbol ||= I18n.t('number.currency.format.unit', default: currency.symbol)
      end

      def raw_value_is_non_numeric
        @raw_value.present? && !@raw_value.is_a?(Numeric)
      end

      def abs_raw_value
        @_abs_raw_value ||= @raw_value.strip.sub(/^-/, "")
      end

      def add_error
        @record.errors.add(@attr, I18n.t('errors.messages.invalid_currency',
                                       { :thousands => thousands_separator,
                                         :decimal => decimal_mark,
                                         :currency => abs_raw_value }))
      end

      def decimal_pieces
        @_decimal_pieces ||= abs_raw_value.split(decimal_mark)
      end

      def value_has_too_many_decimal_points
        ![1, 2].include?(decimal_pieces.length)
      end

      def pieces_array
        @_pieces_array ||= decimal_pieces[0].split(thousands_separator.presence)
      end

      def invalid_thousands_separation
        return false if pieces_array.length <= 1
        return true  if pieces_array[0].length > 3
        pieces_array[1..-1].any? do |thousands_group|
          thousands_group.length != 3
        end
      end

      # Remove thousands separators, normalize decimal mark,
      # remove whitespaces and _ (E.g. 99 999 999 or 12_300_200.20)
      def normalize_raw_value!
        @raw_value = @raw_value.to_s
          .gsub(thousands_separator, '')
          .gsub(decimal_mark, '.')
          .gsub(/[\s_]/, '')
      end
    end
  end
end

# Compatibility with ActiveModel validates method which matches option keys to their validator class
ActiveModel::Validations::MoneyValidator = MoneyRails::ActiveModel::MoneyValidator
