module MoneyRails
  module ActiveModel
    class MoneyValidator < ::ActiveModel::Validations::NumericalityValidator
      class Details < Struct.new(:raw_value, :thousands_separator, :decimal_mark)
        def abs_raw_value
          @abs_raw_value ||= raw_value.to_s.sub(/^\s*-/, "").strip
        end

        def decimal_pieces
          @decimal_pieces ||= abs_raw_value.split(decimal_mark)
        end
      end

      def validate_each(record, attr, _value)
        subunit_attr = record.class.monetized_attributes[attr.to_s]
        currency = record.public_send("currency_for_#{attr}")

        # WARNING: Currently this is only defined in ActiveRecord extension!
        before_type_cast = :"#{attr}_money_before_type_cast"
        raw_value = record.try(before_type_cast)

        # If raw value is nil and changed subunit is nil, then
        # nil is a assigned value, else we should treat the
        # subunit value as the one assigned.
        if raw_value.nil? && record.public_send(subunit_attr)
          subunit_value = record.public_send(subunit_attr)
          raw_value = subunit_value.to_f / currency.subunit_to_unit
        end

        return if options[:allow_nil] && raw_value.nil?

        # Set this before we modify raw_value below.
        stringy = raw_value.present? && !raw_value.is_a?(Numeric) && !raw_value.is_a?(Money)

        if stringy
          # TODO: This is supporting legacy behaviour where a symbol can come from a i18n locale,
          #       however practical implications of that are most likely non-existent
          symbol = lookup(:symbol, currency) || currency.symbol

          # remove currency symbol
          raw_value = raw_value.to_s.gsub(symbol, "")
        end

        # Cache abs_raw_value before normalizing because it's used in
        # many places and relies on the original raw_value.
        details = generate_details(raw_value, currency)
        normalized_raw_value = normalize(details)

        super(record, attr, normalized_raw_value)

        return unless stringy
        return if record_already_has_error?(record, attr, normalized_raw_value)

        add_error!(record, attr, details) if
          value_has_too_many_decimal_points(details) ||
          thousand_separator_after_decimal_mark(details) ||
          invalid_thousands_separation(details)
      end

      private

      DEFAULTS = {
        decimal_mark: '.',
        thousands_separator: ','
      }.freeze

      def generate_details(raw_value, currency)
        thousands_separator = lookup(:thousands_separator, currency)
        decimal_mark = lookup(:decimal_mark, currency)

        Details.new(raw_value, thousands_separator, decimal_mark)
      end

      def record_already_has_error?(record, attr, raw_value)
        record.errors.added?(attr, :not_a_number, value: raw_value)
      end

      def add_error!(record, attr, details)
        attr_name = attr.to_s.tr('.', '_').humanize
        attr_name = record.class.human_attribute_name(attr, default: attr_name)

        record.errors.add(attr, :invalid_currency,
          thousands: details.thousands_separator,
          decimal: details.decimal_mark,
          currency: details.abs_raw_value,
          attribute: attr_name
        )
      end

      def value_has_too_many_decimal_points(details)
        ![1, 2].include?(details.decimal_pieces.length)
      end

      def thousand_separator_after_decimal_mark(details)
        details.thousands_separator.present? &&
          details.decimal_pieces.length == 2 &&
          details.decimal_pieces[1].include?(details.thousands_separator)
      end

      def invalid_thousands_separation(details)
        pieces_array = details.decimal_pieces[0].split(details.thousands_separator.presence)

        return false if pieces_array.length <= 1
        return true  if pieces_array[0].length > 3

        pieces_array[1..-1].any? do |thousands_group|
          thousands_group.length != 3
        end
      end

      # Remove thousands separators, normalize decimal mark,
      # remove whitespaces and _ (E.g. 99 999 999 or 12_300_200.20)
      def normalize(details)
        details.raw_value
          .to_s
          .gsub(details.thousands_separator, '')
          .gsub(details.decimal_mark, '.')
          .gsub(/[\s_]/, '')
      end

      def lookup(key, currency)
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
