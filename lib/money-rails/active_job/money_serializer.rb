# frozen_string_literal: true

module MoneyRails
  module ActiveJob
    class MoneySerializer < ::ActiveJob::Serializers::ObjectSerializer
      def serialize?(argument)
        argument.is_a?(Money)
      end

      def serialize(money)
        super("cents" => money.cents, "currency" => money.currency.to_s)
      end

      def deserialize(hash)
        Money.new(hash["cents"], hash["currency"])
      end

      def klass
        Money
      end
    end
  end
end
