module MoneyRails

  # MoneyRails configuration module.
  # This is extended by MoneyRails to provide configuration settings.
  module Configuration

    # Start a MoneyRails configuration block in an initializer.
    #
    # example: Provide a default currency for the application
    #   MoneyRails.configure do |config|
    #     config.default_currency = :eur
    #   end
    def configure
      yield self
    end

    # Configuration parameters

    # Set default currency of money library
    def default_currency=(currency_name)
      Money.default_currency = Money::Currency.new(currency_name)
    end

    # Register a custom currency
    def register_currency=(currency_options)
      Money::Currency.register(currency_options)
    end

    # Use (by default) validation of numericality for each monetized field.
    mattr_accessor :include_validations
    @@include_validations = true
  end
end
