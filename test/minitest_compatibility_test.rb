# frozen_string_literal: true

# This test demonstrates that money-rails test helpers work with minitest
# To run: bundle exec ruby test/minitest_compatibility_test.rb

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'minitest/autorun'
require 'active_support/core_ext/object/blank'
require 'money'
require 'monetize'
require 'money-rails/test_helpers'

# Mock Product class that simulates a monetized model
class MockProduct
  attr_accessor :price_cents, :discount, :optional_price_cents, :bonus_cents,
                :sale_price_amount
  attr_writer :sale_price_currency_code

  def initialize(attrs = {})
    attrs.each { |k, v| public_send("#{k}=", v) }
  end

  def sale_price_currency_code
    return nil unless @sale_price_currency_code
    # Return Money::Currency object for proper comparison
    Money::Currency.new(@sale_price_currency_code)
  end

  def price
    @price ||= Money.new(price_cents || 0, 'USD')
  end

  def price=(value)
    @price = value.is_a?(Money) ? value : Money.new(value * 100, 'USD')
    @price_cents = @price.cents
  end

  def discount_value
    @discount_value ||= Money.new(discount || 0, 'USD')
  end

  def discount_value=(value)
    @discount_value = value.is_a?(Money) ? value : Money.new(value * 100, 'USD')
    @discount = @discount_value.cents
  end

  def optional_price
    return nil if optional_price_cents.nil? || optional_price_cents == ""
    Money.new(optional_price_cents, 'USD')
  end

  def optional_price=(value)
    if value.nil? || value == ""
      @optional_price_cents = nil
      return nil
    end
    @optional_price = value.is_a?(Money) ? value : Money.new(value * 100, 'USD')
    @optional_price_cents = @optional_price.cents
  end

  def bonus
    @bonus ||= Money.new(bonus_cents || 0, 'GBP')
  end

  def bonus=(value)
    @bonus = value.is_a?(Money) ? value : Money.new(value * 100, 'GBP')
    @bonus_cents = @bonus.cents
  end

  def sale_price
    return nil unless sale_price_amount
    currency = @sale_price_currency_code || 'USD'
    Money.new(sale_price_amount, currency)
  end

  def sale_price=(value)
    if value.is_a?(Money)
      @sale_price_amount = value.cents
      @sale_price_currency_code ||= value.currency.id
    elsif value.is_a?(Numeric)
      currency = @sale_price_currency_code || 'USD'
      money = Money.new(value * 100, currency)
      @sale_price_amount = money.cents
    end
  end
end

# Minitest test class
class TestHelpersTest < Minitest::Test
  include MoneyRails::TestHelpers

  def setup
    @product = MockProduct.new(
      price_cents: 3000,
      discount: 150,
      bonus_cents: 200,
      sale_price_amount: 1200,
      sale_price_currency_code: 'USD'
    )
  end

  def test_monetize_matcher_with_basic_attribute
    matcher = monetize(:price_cents)
    assert matcher.matches?(@product.class), "Expected price_cents to be monetized"
  end

  def test_monetize_matcher_with_as_option
    matcher = monetize(:discount).as(:discount_value)
    assert matcher.matches?(@product.class), "Expected discount to be monetized as discount_value"
  end

  def test_monetize_matcher_with_allow_nil
    matcher = monetize(:optional_price_cents).allow_nil
    assert matcher.matches?(@product.class), "Expected optional_price_cents to allow nil"
  end

  def test_monetize_matcher_with_currency
    matcher = monetize(:bonus_cents).with_currency(:gbp)
    assert matcher.matches?(@product.class), "Expected bonus_cents to use GBP currency"
  end

  # Note: with_model_currency test omitted as it requires more complex ActiveRecord-specific setup
  # The main functionality (loading test_helpers without RSpec) is proven by the other tests

  def test_monetize_matcher_fails_for_non_existent_attribute
    matcher = monetize(:fake_attribute)
    refute matcher.matches?(@product.class), "Expected matcher to fail for non-existent attribute"
  end

  def test_monetize_matcher_fails_for_wrong_currency
    matcher = monetize(:bonus_cents).with_currency(:usd)
    refute matcher.matches?(@product.class), "Expected matcher to fail for wrong currency"
  end

  def test_matcher_description
    matcher = monetize(:price_cents)
    assert_equal "monetize price_cents", matcher.description
  end

  def test_matcher_failure_message
    matcher = monetize(:price_cents)
    matcher.matches?(@product.class)
    assert_includes matcher.failure_message, "price_cents"
  end

  def test_test_helpers_loaded_without_rspec
    # This test verifies that test_helpers can be loaded without RSpec
    # If we got here, it means the require didn't fail
    assert defined?(MoneyRails::TestHelpers), "TestHelpers module should be defined"
    assert defined?(MoneyRails::TestHelpers::MonetizeMatcher), "MonetizeMatcher should be defined"
  end
end
