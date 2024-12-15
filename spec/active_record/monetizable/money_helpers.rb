module MoneyHelpers
  # -----------------------
  # Instance Checks
  # -----------------------

  def expect_to_be_a_money_instance(value)
    expect(value).to be_an_instance_of(Money)
  end

  def expect_to_have_money_attributes(model, *attributes)
    attributes.each do |attribute|
      expect_to_be_a_money_instance(model.send(attribute))
    end
  end

  def expect_to_be_a_currency_instance(value)
    expect(value).to be_an_instance_of(Money::Currency)
  end

  # -----------------------
  # Currency Checks
  # -----------------------

  def expect_currency_is(currency, currency_symbol)
    expected_currency = Money::Currency.find(currency_symbol)

    expect_equal_currency(currency, expected_currency)
  end

  def expect_equal_currency(currency, expected_currency)
    expect_to_be_a_currency_instance(expected_currency)

    expect(currency).to eq(expected_currency)
  end

  def expect_currency_iso_code(currency, expected_iso_code)
    expect(currency.iso_code).to eq(expected_iso_code)
  end

  def expect_money_currency_is(value, currency_symbol)
    expect_currency_is(value.currency, currency_symbol)
  end

  def expect_equal_money_currency(value, expected_value)
    expect(value.currency).to eq(expected_value.currency)
  end

  def expect_money_currency_code(value, expected_currency_code)
    expect(value.currency.to_s).to eq(expected_currency_code)
  end

  # -----------------------
  # Money Value Checks
  # -----------------------

  def expect_equal_money_instance(current_money, amount:, currency:)
    expected_money = Money.new(amount, currency)

    expect(current_money).to eq(expected_money)
  end

  def expect_equal_money(current_money, expected_money)
    expect_to_be_a_money_instance(expected_money)

    expect(current_money).to eq(expected_money)
  end

  def expect_money_cents_value(model, expected_cents)
    expect(model.cents).to eq(expected_cents)
  end

  def expect_equal_money_cents(model, expected_model)
    expect_money_cents_value(model, expected_model.cents)
  end

  # -----------------------
  # Money Attribute Checks
  # -----------------------

  def expect_money_attribute_cents_value(model, money_attribute, expected_cents)
    model_cents = model.send("#{money_attribute}_cents")

    expect(model_cents).to eq(expected_cents)
  end

  def expect_money_attribute_currency_value(model, money_attribute, expected_currency)
    model_currency = model.send("#{money_attribute}_currency")

    expect(model_currency).to eq(expected_currency)
  end
end
