class Service < ActiveRecord::Base
  monetize :charge_cents, :with_currency => :usd

  monetize :discount_cents
end
