class Transaction < ActiveRecord::Base
  monetize :amount_cents, with_model_currency: :currency,
                          subunit_numericality: {
                            only_integer: true,
                            greater_than: 0,
                            less_than_or_equal_to: 2_000_000,
                          },
                          numericality: {
                            greater_than: 0,
                            less_than_or_equal_to: 20_000
                          }

  monetize :tax_cents, with_model_currency: :currency

  monetize :total_cents, with_model_currency: :currency

  monetize :optional_amount_cents, with_model_currency: :currency, allow_nil: true

  def total_cents(foo = 0, bar: 0)
    amount_cents + tax_cents + foo + bar
  end
end
