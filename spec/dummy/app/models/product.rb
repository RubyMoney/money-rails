class Product < ActiveRecord::Base

  attr_accessible :price_cents, :discount

  # Use money-rails macros
  monetize :price_cents
  monetize :discount, :target_name => "discount_value"

end
