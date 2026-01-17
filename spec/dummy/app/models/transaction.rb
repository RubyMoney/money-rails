class Transaction < ApplicationRecord
  monetize :amount_cents, with_model_currency: :currency

  monetize :tax_cents, with_model_currency: :currency

  monetize :total_cents, with_model_currency: :currency

  monetize :optional_amount_cents, with_model_currency: :currency, allow_nil: true

  def total_cents(foo = 0, bar: 0)
    amount_cents + tax_cents + foo + bar
  end
end
