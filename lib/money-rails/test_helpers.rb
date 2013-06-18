require 'rspec/expectations'

module MoneyRails
  module TestHelpers
    extend RSpec::Matchers::DSL

    matcher :monetize do |attr|

      chain(:with_currency) do |currency|
        @currency_iso = currency
      end

      chain(:as) do |virt_attr|
        @as = virt_attr
      end

      match do |target|
        matched = true
        money_attr = @as.presence || attr.to_s.sub(/_cents$/, "")
        matched = false if !target.respond_to?(money_attr) ||
          !target.send(money_attr).instance_of?(Money) ||
          (@currency_iso &&
           target.send(money_attr.to_sym).currency.id != @currency_iso)
        matched
      end

      description do
        description = "monetize #{attr}"
        description << " as #{@as}" if @as
        description << " with currency #{@currency_iso}" if @currency_iso
        description
      end

      failure_message_for_should do |actual|
        msg = "expected that #{attr} of #{actual} would be monetized"
        msg << " as #{@as}" if @as
        msg << " with currency #{@currency_iso}" if @currency_iso
        msg
      end

      failure_message_for_should_not do |actual|
        msg = "expected that #{attr} of #{actual} would not be monetized"
        msg << " as #{@as}" if @as
        msg << " with currency #{@currency_iso}" if @currency_iso
        msg
      end
    end
  end
end
