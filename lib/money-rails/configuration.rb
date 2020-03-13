require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/string/inflections'

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

    def default_currency
      Money::Currency.new(Money.default_currency)
    end

    # Set default currency of money library
    def default_currency=(currency_name)
      Money.default_currency = currency_name
      set_currency_column_for_default_currency!
    end

    # Register a custom currency
    def register_currency=(currency_options)
      Money::Currency.register(currency_options)
    end

    def set_currency_column_for_default_currency!
      iso_code = default_currency.iso_code
      currency_column.merge! default: iso_code
    end

    def rounding_mode=(mode)
      valid_modes = [
        BigDecimal::ROUND_UP,
        BigDecimal::ROUND_DOWN,
        BigDecimal::ROUND_HALF_UP,
        BigDecimal::ROUND_HALF_DOWN,
        BigDecimal::ROUND_HALF_EVEN,
        BigDecimal::ROUND_CEILING,
        BigDecimal::ROUND_FLOOR
      ]
      raise ArgumentError, "#{mode} is not a valid rounding mode" unless valid_modes.include?(mode)
      Money.rounding_mode = mode
    end
    # Set default bank object
    #
    # example (given that eu_central_bank is in Gemfile):
    #   MoneyRails.configure do |config|
    #     config.default_bank = EuCentralBank.new
    #   end
    delegate :default_bank=, :default_bank, :locale_backend, :locale_backend=, to: :Money

    # Provide exchange rates
    delegate :add_rate, to: :Money

    # Use (by default) validation of numericality for each monetized field.
    mattr_accessor :include_validations
    @@include_validations = true

    # Default ActiveRecord migration configuration values for columns
    mattr_accessor :amount_column
    @@amount_column = { postfix: '_cents', type: :integer, null: false, default: 0, present: true }

    mattr_accessor :currency_column
    @@currency_column = { postfix: '_currency', type: :string, null: false, default: 'USD', present: true }

    # Use nil values to ignore defaults
    mattr_accessor :no_cents_if_whole
    @@no_cents_if_whole = nil

    mattr_accessor :symbol
    @@symbol = nil

    mattr_accessor :sign_before_symbol
    @@sign_before_symbol = nil

    mattr_accessor :default_format
    @@default_format = nil

    # Configure whether to raise exception when an improper value
    # is going to be converted to a Money object.
    mattr_accessor :raise_error_on_money_parsing
    @@raise_error_on_money_parsing = false

    #Configure whether to maintain invalid user input after validations
    mattr_accessor :preserve_user_input
    @@preserve_user_input = false
  end
end
