class Service < ActiveRecord::Base
  attr_accessible :charge_cents, :discount_cents

  monetize :charge_cents, :with_currency => :usd

  monetize :discount_cents
end
