module MoneyRails
  module ActionViewExtension

    def currency_symbol
      content_tag(:span, Money.default_currency.symbol, :class => "currency_symbol")
    end

    def humanized_money(value, options={})
      if !options || !options.is_a?(Hash)
        warn "humanized_money now takes a hash of formatting options, please specify { :symbol => true }"
        options = { :symbol => options }
      end

      unless value.is_a?(Money)
        if value.respond_to?(:to_money)
          value = value.to_money
        else
          return ''
        end
      end

      options = {
        :no_cents_if_whole   => MoneyRails::Configuration.no_cents_if_whole.nil? ? true : MoneyRails::Configuration.no_cents_if_whole,
        :symbol              => false,
        :decimal_mark        => value.currency.decimal_mark,
        :thousands_separator => value.currency.thousands_separator
      }.merge(options)
      options.delete(:symbol) if options[:disambiguate]

      value.format(options)
    end

    def humanized_money_with_symbol(value, options={})
      humanized_money(value, options.merge(:symbol => true))
    end

    def money_without_cents(value, options={})
      if !options || !options.is_a?(Hash)
        warn "money_without_cents now takes a hash of formatting options, please specify { :symbol => true }"
        options = { :symbol => options }
      end

      options = {
        :no_cents => true,
        :no_cents_if_whole => false,
        :symbol => false
      }.merge(options)

      humanized_money(value, options)
    end

    def money_without_cents_and_with_symbol(value)
      money_without_cents(value, :symbol => true)
    end
  end
end
