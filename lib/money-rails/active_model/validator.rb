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
        return if raw_value.is_a?(Money) || raw_value.nil?

        if !raw_value.blank?
          # remove currency symbol, and negative sign
          currency = record.send("currency_for_#{attr}")
          raw_value = raw_value.to_s.gsub(currency.symbol, "").gsub(/^-/, "")
          
          decimal_pieces = raw_value.split(currency.decimal_mark)
          # check for numbers like 12.23.45
          if decimal_pieces.length > 2
            record.errors.add(attr, I18n.t('errors.messages.invalid_currencym', { :thousands => currency.thousands_separator, :decimal => currency.decimal_mark }))
          end

          pieces = decimal_pieces[0].split(currency.thousands_separator)
          if pieces.length > 1
            record.errors.add(attr, I18n.t('errors.messages.invalid_currencym', { :thousands => currency.thousands_separator, :decimal => currency.decimal_mark })) unless pieces[0].length <= 3
            (1..pieces.length-1).each do |index|
              record.errors.add(attr, I18n.t('errors.messages.invalid_currencym', { :thousands => currency.thousands_separator, :decimal => currency.decimal_mark })) unless pieces[index].length == 3
            end
          end
          # remove thousands separators
          raw_value = raw_value.to_s.gsub(currency.thousands_separator, '')
          # normalize decimal mark
          raw_value = raw_value.to_s.gsub(currency.decimal_mark, '.')
        end
        super(record, attr, raw_value)
      end
    end
  end
end
