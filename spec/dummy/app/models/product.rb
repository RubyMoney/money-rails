class Product < ActiveRecord::Base
  # Use USD as model level currency
  register_currency :usd

  # Use money-rails macros
  monetize :price_cents

  # Use money-rails macro with multiple fields
  monetize :delivery_fee_cents, :restock_fee_cents, allow_nil: true

  # Use a custom name for the Money attribute
  monetize :discount, as: "discount_value"

  # Allow nil
  monetize :optional_price_cents, allow_nil: true

  # Override default currency (EUR) with a specific one (GBP) for this field only
  monetize :bonus_cents, with_currency: :gbp

  # Use currency column to determine currency for this field only
  monetize :sale_price_amount, as: :sale_price,
    with_model_currency: :sale_price_currency_code

  monetize :price_in_a_range_cents, allow_nil: true,
                                    subunit_numericality: {
                                      greater_than: 0,
                                      less_than_or_equal_to: 10000
                                    },
                                    numericality: {
                                      greater_than: 0,
                                      less_than_or_equal_to: 100,
                                      message: "must be greater than zero and less than $100"
                                    }

  # Skip validations separately from each other
  monetize :skip_validation_price_cents, subunit_numericality: false, numericality: false, allow_nil: true

  # Override default currency (EUR) with a specific one (CAD) for this field only, from a lambda
  monetize :lambda_price_cents, with_currency: ->(_product) { Rails.configuration.lambda_test }, allow_nil: true

  attr_accessor :accessor_price_cents
  monetize :accessor_price_cents, disable_validation: true

  monetize :validates_method_amount_cents, allow_nil: true

  validates :validates_method_amount, money: {
                                        greater_than: 0,
                                        less_than_or_equal_to: ->(product) { product.optional_price.to_f },
                                        message: 'must be greater than zero and less than $100',
                                      },
                                      allow_nil: true

  alias_attribute :renamed_cents, :aliased_cents

  monetize :renamed_cents, allow_nil: true

  # Using postfix to determine currency column (reduced_price_currency)
  monetize :reduced_price_cents, allow_nil: true
end
