MoneyRails.configure do |config|

  # To set the default currency
  #
  config.default_currency = :eur

  # To handle the inclusion of validations for monetized fields
  # The default value is true
  #
  config.include_validations = true
end
