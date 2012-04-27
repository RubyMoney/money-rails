module MoneyRails

  # MoneyRails configuration module.
  # This is extended by MoneyRails to provide configuration settings.
  module Configuration

    # Start a MoneyRails configuration block in an initializer.
    #
    # example: Provide a default currency for the application
    #   MoneyRails.configure do |config|
    #     config.default_currency :eur
    #   end
    def configure
      yield self
    end

    # Set default currency of money library
    def default_currency(currency_name)
      Money.default_currency = Money::Currency.new(currency_name)
    end
  end
end
