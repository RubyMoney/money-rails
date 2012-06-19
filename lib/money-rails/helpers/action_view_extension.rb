module MoneyRails
  module ActionViewExtension

    def currency_symbol
      content_tag(:span, Money.default_currency.symbol, :class => "currency_symbol")
    end

    def humanized_money(value, symbol=false)
      if value.is_a?(Money)
        value.format(no_cents_if_whole: true, symbol: symbol)
      elsif value.respond_to?(:to_money)
        value.to_money.format(no_cents_if_whole: true, symbol: symbol)
      else
        ""
      end
    end

    def humanized_money_with_symbol(value)
      humanized_money(value, true)
    end

    def money_without_cents(value, symbol=false)
      if value.is_a?(Money)
        value.format(no_cents: true, symbol: symbol)
      elsif value.respond_to?(:to_money)
        value.to_money.format(no_cents: true, symbol: symbol)
      else
        ""
      end
    end

    def money_without_cents_and_with_symbol(value)
      money_without_cents(value, true)
    end
  end
end
