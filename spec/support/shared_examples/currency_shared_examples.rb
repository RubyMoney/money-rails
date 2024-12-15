RSpec.shared_examples "currency detection" do |&block|
  it "detects currency based on instance currency name" do
    product = Product.new(sale_price_currency_code: 'CAD')
    currency = product.send(:currency_for, :sale_price, :sale_price_currency_code, nil)

    block.call(product, currency)
  end

  it "detects currency based on currency passed as a block" do
    product = Product.new
    currency = product.send(:currency_for, :lambda_price, nil, ->(_) { 'CAD' })

    block.call(product, currency)
  end

  it "detects currency based on currency passed explicitly" do
    product = Product.new
    currency = product.send(:currency_for, :bonus, nil, 'CAD')

    block.call(product, currency)
  end
end
