module MoneyRails
  module ActionViewExtension

    def currency_symbol
      content_tag(:span, Money.default_currency.symbol, :class => "currency_symbol")
    end
  end
end
