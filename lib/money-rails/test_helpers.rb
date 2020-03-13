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

      def with_model_currency(attribute)
        @currency_attribute = attribute
        self
      end

      def as(virt_attr)
        @as = virt_attr
        self
      end

      def allow_nil
        @allow_nil = true
        self
      end

      def matches?(actual)
        if actual.is_a?(Class)
          @actual = actual.new
        else
          @actual = actual.class.new
        end

        @money_attribute = @as.presence || @attribute.to_s.sub(/_cents$/, "")
        @money_attribute_setter = "#{@money_attribute}="

        object_responds_to_attributes? &&
          test_allow_nil &&
          is_monetized? &&
          test_currency_iso &&
          test_currency_attribute
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

      private

      def object_responds_to_attributes?
        @actual.respond_to?(@attribute) && @actual.respond_to?(@money_attribute)
      end

      def test_allow_nil
        if @allow_nil
          @actual.public_send(@money_attribute_setter, "")
          @actual.public_send(@money_attribute).nil?
        else
          true
        end
      end

      def is_monetized?
        @actual.public_send(@money_attribute_setter, 1)
        @actual.public_send(@money_attribute).instance_of?(Money)
      end

      def test_currency_iso
        if @currency_iso
          @actual.public_send(@money_attribute).currency.id == @currency_iso
        else
          true
        end
      end

      def test_currency_attribute
        if @currency_attribute
          @actual.public_send(@money_attribute).currency == @actual.public_send(@currency_attribute)
        else
          true
        end
      end

    end
  end
end

RSpec.configure do |config|
  config.include MoneyRails::TestHelpers
end
