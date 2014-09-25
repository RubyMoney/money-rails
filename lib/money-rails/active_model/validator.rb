module MoneyRails
  module ActiveModel
    class MoneyValidator < ::ActiveModel::Validations::NumericalityValidator
      def validate_each(record, attr, value)
        @record = record
        @attr = attr

        # If subunit is not set then no need to validate as it is an
        # indicator that no assignment has been done onto the virtual
        # money field.
        subunit_attr = @record.class.monetized_attributes[@attr.to_sym]
        return unless @record.changed_attributes.keys.include? subunit_attr

        # WARNING: Currently this is only defined in ActiveRecord extension!
        before_type_cast = :"#{@attr}_money_before_type_cast"
        @raw_value = @record.try(before_type_cast)

        # If raw value is nil and changed subunit is nil, then
        # nil is a assigned value, elsewhere we should treat the
        # subunit value as the one assigned.
        if @raw_value.nil? && @record.send(subunit_attr)
          @raw_value = @record.send(subunit_attr)
        end

        return if options[:allow_nil] && @raw_value.nil?

        # Skip normalization for Numeric values
        # which can directly be handled by NumericalityValidator
        if raw_value_is_non_numeric
          # remove currency symbol, and negative sign
          @raw_value = @raw_value.to_s.strip.gsub(symbol, "")

          # check for numbers like '12.23.45' or '....'
          if value_has_too_many_decimal_points
            add_error
            return
          end

          pieces = decimal_pieces[0].split(thousands_separator)

          # check for valid thousands separation
          if pieces.length > 1
            add_error if pieces[0].length > 3
            (1..pieces.length-1).each do |index|
              add_error if pieces[index].length != 3
            end
          end

          # Remove thousands separators, normalize decimal mark,
          # remove whitespaces and _ (E.g. 99 999 999 or 12_300_200.20)
          @raw_value = @raw_value.to_s
            .gsub(thousands_separator, '')
            .gsub(decimal_mark, '.')
            .gsub(/[\s_]/, '')
        end

        super(@record, @attr, @raw_value)
      end

      private

      def currency
        @_currency ||= @record.send("currency_for_#{@attr}")
      end

      def decimal_mark
        I18n.t('number.currency.format.separator', default: currency.decimal_mark)
      end

      def thousands_separator
        I18n.t('number.currency.format.delimiter', default: currency.thousands_separator)
      end

      def symbol
        I18n.t('number.currency.format.unit', default: currency.symbol)
      end

      def raw_value_is_non_numeric
        @raw_value.present? && !@raw_value.is_a?(Numeric)
      end

      def abs_raw_value
       @raw_value.strip.sub(/^-/, "")
      end

      def add_error
        @record.errors.add(@attr, I18n.t('errors.messages.invalid_currency',
                                       { :thousands => thousands_separator,
                                         :decimal => decimal_mark,
                                         :currency => abs_raw_value }))
      end

      def decimal_pieces
        abs_raw_value.split(decimal_mark)
      end

      def value_has_too_many_decimal_points
        ![1, 2].include?(decimal_pieces.length)
      end
    end
  end
end

# Compatibility with ActiveModel validates method which matches option keys to their validator class
ActiveModel::Validations::MoneyValidator = MoneyRails::ActiveModel::MoneyValidator
