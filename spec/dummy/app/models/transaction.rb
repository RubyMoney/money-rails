class Transaction < ActiveRecord::Base

  attr_accessible :amount_cents, :currency, :tax_cents, :amount, :tax

  monetize :amount_cents
  monetize :tax_cents

  monetize :total_cents
  def total_cents
    return amount_cents + tax_cents
  end

end
