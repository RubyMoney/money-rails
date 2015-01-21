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

      options = {
        :no_cents_if_whole => MoneyRails::Configuration.no_cents_if_whole.nil? ? true : MoneyRails::Configuration.no_cents_if_whole,
        :symbol => false
      }.merge(options)
      options.delete(:symbol) if options[:disambiguate]

      if value.is_a?(Money)
        value.format(options)
      elsif value.respond_to?(:to_money)
        value.to_money.format(options)
      else
        ""
      end
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
