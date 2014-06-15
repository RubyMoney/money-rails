class Transaction < ActiveRecord::Base
  monetize :amount_cents, :with_model_currency => :currency

  monetize :tax_cents, :with_model_currency => :currency

  monetize :total_cents, :with_model_currency => :currency

  def total_cents
    return amount_cents + tax_cents
  end
end
