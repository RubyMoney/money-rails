class Transaction < ActiveRecord::Base

  attr_accessible :amount_cents, :currency, :tax_cents

  monetize :amount_cents
  monetize :tax_cents

end
