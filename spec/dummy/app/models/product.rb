class Product < ActiveRecord::Base

  attr_accessible :price_cents, :discount, :bonus_cents

  # Use money-rails macros
  monetize :price_cents

  # Use a custom name for the Money attribute
  monetize :discount, :target_name => "discount_value"

  # Override default currency (USD) with a specific one (EUR) for this field only
  monetize :bonus_cents, :field_currency => :eur

end
