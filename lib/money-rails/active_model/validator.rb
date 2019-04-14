module MoneyRails
  module ActiveModel
    class MoneyValidator < ::ActiveModel::Validations::NumericalityValidator
      def validate_each(record, attr, _value)
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

        # Set this before we modify @raw_value below.
        stringy = @raw_value.present? && !@raw_value.is_a?(Numeric) && !@raw_value.is_a?(Money)

        if stringy
          # remove currency symbol
          @raw_value = @raw_value.to_s.gsub(symbol, "")
        end

        normalize_raw_value!
        super(@record, @attr, @raw_value)

        if stringy && record_does_not_have_error?
          add_error if
            value_has_too_many_decimal_points ||
            thousand_separator_after_decimal_mark ||
            invalid_thousands_separation
        end
      end

      private

      DEFAULTS = {
        decimal_mark: '.',
        thousands_separator: ','
      }.freeze

      def record_does_not_have_error?
        !@record.errors.added?(@attr, :not_a_number, value: @raw_value)
      end

      def reset_memoized_variables!
        [:currency, :decimal_mark, :thousands_separator, :symbol,
          :abs_raw_value, :decimal_pieces, :pieces_array].each do |var_name|
          ivar_name = :"@_#{var_name}"
          remove_instance_variable(ivar_name) if instance_variable_defined?(ivar_name)
        end
      end

      def currency
        @_currency ||= @record.public_send("currency_for_#{@attr}")
      end

      def decimal_mark
        @_decimal_mark ||= lookup(:decimal_mark)
      end

      def thousands_separator
        @_thousands_separator ||= lookup(:thousands_separator)
      end

      # TODO: This is supporting legacy behaviour where a symbol can come from a i18n locale,
      #       however practical implications of that are most likely non-existent
      def symbol
        @_symbol ||= lookup(:symbol) || currency.symbol
      end

      def abs_raw_value
        @_abs_raw_value ||= @raw_value.to_s.sub(/^\s*-/, "").strip
      end

      def add_error
        attr_name = @attr.to_s.tr('.', '_').humanize
        attr_name = @record.class.human_attribute_name(@attr, default: attr_name)

        @record.errors.add(@attr, :invalid_currency,
                           { thousands: thousands_separator,
                             decimal: decimal_mark,
                             currency: abs_raw_value,
                             attribute: attr_name })
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

      def thousand_separator_after_decimal_mark
        thousands_separator.present? && decimal_pieces.length == 2 && decimal_pieces[1].include?(thousands_separator)
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
        # Cache abs_raw_value before normalizing because it's used in
        # many places and relies on the original @raw_value.
        abs_raw_value

        @raw_value = @raw_value.to_s
          .gsub(thousands_separator, '')
          .gsub(decimal_mark, '.')
          .gsub(/[\s_]/, '')
      end

      def lookup(key)
        if locale_backend
          locale_backend.lookup(key, currency) || DEFAULTS[key]
        else
          DEFAULTS[key]
        end
      end

      def locale_backend
        Money.locale_backend
      end
    end
  end
end

# Compatibility with ActiveModel validates method which matches option keys to their validator class
ActiveModel::Validations::MoneyValidator = MoneyRails::ActiveModel::MoneyValidator
