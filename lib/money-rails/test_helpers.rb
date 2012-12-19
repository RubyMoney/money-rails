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
        matched = false unless target.send(money_attr).instance_of? Money
        if @currency_iso
          matched = false unless target.send(money_attr.to_sym).currency.id == @currency_iso
        end
        matched
      end

      description do
        description = "monetize #{expected}"
        description << " as #{@as}" if @as
        description << " with currency #{@currency_iso}" if @currency_iso
        description
      end

      failure_message_for_should do |actual|
        msg = "expected that #{actual} would be monetized"
        msg << " as #{@as}" if @as
        msg << " with currency #{@currency_iso}" if @currency_iso
        msg
      end

      failure_message_for_should_not do |actual|
        msg = "expected that #{actual} would not be monetized"
        msg << " as #{@as}" if @as
        msg << " with currency #{@currency_iso}" if @currency_iso
        msg
      end
    end
  end
end
