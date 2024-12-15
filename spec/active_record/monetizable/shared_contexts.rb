RSpec.shared_context "monetizable product setup" do
  let(:product) do
    Product.create(
      price_cents: 3000,
      discount: 150,
      bonus_cents: 200,
      optional_price: 100,
      sale_price_amount: 1200,
      delivery_fee_cents: 100,
      restock_fee_cents: 2000,
      reduced_price_cents: 1500,
      reduced_price_currency: :lvl,
      lambda_price_cents: 4000
    )
  end
end
