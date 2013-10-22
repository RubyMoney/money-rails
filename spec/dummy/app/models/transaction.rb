class Transaction < ActiveRecord::Base

  attr_accessible :amount_cents, :currency, :tax_cents, :amount, :tax

  monetize :amount_cents, :with_model_currency => :currency
  monetize :tax_cents, :with_model_currency => :currency

  monetize :total_cents, :with_model_currency => :currency
  def total_cents
    return amount_cents + tax_cents
  end

end
