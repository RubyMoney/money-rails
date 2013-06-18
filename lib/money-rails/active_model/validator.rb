module MoneyRails
  module ActiveModel
    class MoneyValidator < ::ActiveModel::Validations::NumericalityValidator
      def validate_each(record, attr, value)

        # If subunit is not set then no need to validate as it is an
        # indicator that no assignment has been done onto the virtual
        # money field.
        subunit_attr = record.class.monetized_attributes[attr.to_sym]
        return unless record.changed_attributes.keys.include? subunit_attr

        # WARNING: Currently this is only defined in ActiveRecord extension!
        before_type_cast = "#{attr}_money_before_type_cast"
        raw_value = record.send(before_type_cast) if record.respond_to?(before_type_cast.to_sym)

        # Skip it if raw_value is already a Money object
        return if raw_value.nil?

        if raw_value.present?
          # remove currency symbol, and negative sign
          currency = record.send("currency_for_#{attr}")
          decimal_mark = I18n.t('number.currency.format.separator',
                                default: currency.decimal_mark)
          thousands_separator = I18n.t('number.currency.format.delimiter',
                                       default: currency.thousands_separator)
          symbol = I18n.t('number.currency.format.unit', default: currency.symbol)

          raw_value = raw_value.to_s.strip.gsub(symbol, "")
          abs_raw_value = raw_value.gsub(/^-/, "")

          decimal_pieces = abs_raw_value.split(decimal_mark)

          # check for numbers like '12.23.45' or '....'
          unless [1, 2].include? decimal_pieces.length
            record.errors.add(attr, I18n.t('errors.messages.invalid_currency',
                                           { :thousands => thousands_separator,
                                             :decimal => decimal_mark }))
            return
          end

          pieces = decimal_pieces[0].split(thousands_separator)

          # check for valid thousands separation
          if pieces.length > 1
            record.errors.add(attr, I18n.t('errors.messages.invalid_currency',
                                           { :thousands => thousands_separator,
                                             :decimal => decimal_mark })) if pieces[0].length > 3
            (1..pieces.length-1).each do |index|
              record.errors.add(attr, I18n.t('errors.messages.invalid_currency',
                                             { :thousands => thousands_separator,
                                               :decimal => decimal_mark })) if pieces[index].length != 3
            end
          end

          # Remove thousands separators, normalize decimal mark,
          # remove whitespaces and _ (E.g. 99 999 999 or 12_300_200.20)
          raw_value = raw_value.to_s
            .gsub(thousands_separator, '')
            .gsub(decimal_mark, '.')
            .gsub(/[\s_]/, '')
        end

        super(record, attr, raw_value)
      end
    end
  end
end
