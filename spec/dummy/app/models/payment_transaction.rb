class PaymentTransaction < ActiveRecord::Base

  attr_accessible :acquirer_id, :amount_cents, :amount_currency, :tax_cents, :tax_currency

  monetize :amount_cents
  monetize :tax_cents

  monetize :total_cents
  def total_cents
    return amount_cents + tax_cents
  end

end
