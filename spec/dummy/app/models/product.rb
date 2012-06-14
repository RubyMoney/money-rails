class Product < ActiveRecord::Base

  attr_accessible :price_cents, :discount, :bonus_cents,
    :price, :discount_value, :bonus, :optional_price_cents, :optional_price

  # Use USD as model level currency
  register_currency :usd

  # Use money-rails macros
  monetize :price_cents

  # Use a custom name for the Money attribute
  monetize :discount, :as => "discount_value"

  # Allow nil
  monetize :optional_price_cents, :allow_nil => true

  # Override default currency (EUR) with a specific one (GBP) for this field only
  monetize :bonus_cents, :with_currency => :gbp

end
