# encoding : utf-8

MoneyRails.configure do |config|

  # To set the default currency
  #
  config.default_currency = :eur

  # Add some rates
  config.add_rate "USD", "CAD", 1.24515
  config.add_rate "CAD", "USD", 0.803115

  # To handle the inclusion of validations for monetized fields
  # The default value is true
  #
  config.include_validations = true

  # Register a custom currency
  #
  config.register_currency = {
    priority:            1,
    iso_code:            "EU4",
    name:                "Euro with subunit of 4 digits",
    symbol:              "€",
    symbol_first:        true,
    subunit:             "Subcent",
    subunit_to_unit:     10000,
    thousands_separator: ".",
    decimal_mark:        ","
  }
end
