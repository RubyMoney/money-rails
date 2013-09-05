RSpec::Matchers.define :have_currency do |currency|
  match do |money|
    money.currency_as_string == currency
  end

  failure_message_for_should do |money|
    "expected the money to have currency #{currency} but it was #{money.currency_as_string}"
  end

  failure_message_for_should_not do |money|
    "expected the money to not have currency #{currency}"
  end

end