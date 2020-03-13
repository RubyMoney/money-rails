class DummyProduct < ActiveRecord::Base
  # Use  as model level currency
  register_currency :gbp

  # Use money-rails macros
  monetize :price_cents, with_model_currency: :currency
end

