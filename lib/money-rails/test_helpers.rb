require 'rspec/expectations'

module MoneyRails
  module TestHelpers
    def monetize(attribute)
      MonetizeMatcher.new(attribute)
    end

    class MonetizeMatcher
      def initialize(attribute)
        @attribute = attribute
      end

      def with_currency(currency)
        @currency_iso = currency
        self
      end

      def as(virt_attr)
        @as = virt_attr
        self
      end

      def matches?(actual)
        @actual = actual

        matched = true
        money_attr = @as.presence || @attribute.to_s.sub(/_cents$/, "")
        matched = false if !actual.respond_to?(money_attr) ||
          !actual.send(money_attr).instance_of?(Money) ||
          (@currency_iso &&
           actual.send(money_attr.to_sym).currency.id != @currency_iso)
        matched
      end

      def description
        desc = "monetize #{@attribute}"
        desc << " as #{@as}" if @as
        desc << " with currency #{@currency_iso}" if @currency_iso
        desc
      end

      def failure_message # RSpec 3.x
        msg = "expected that #{@attribute} of #{@actual} would be monetized"
        msg << " as #{@as}" if @as
        msg << " with currency #{@currency_iso}" if @currency_iso
        msg
      end
      alias_method :failure_message_for_should, :failure_message # RSpec 1.2, 2.x, and minitest-matchers

      def failure_message_when_negated # RSpec 3.x
        msg = "expected that #{@attribute} of #{@actual} would not be monetized"
        msg << " as #{@as}" if @as
        msg << " with currency #{@currency_iso}" if @currency_iso
        msg
      end
      alias_method :failure_message_for_should_not, :failure_message_when_negated # RSpec 1.2, 2.x, and minitest-matchers
      alias_method :negative_failure_message,       :failure_message_when_negated # RSpec 1.1
    end
  end
end

RSpec.configure do |config|
  config.include MoneyRails::TestHelpers
end
