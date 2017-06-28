module MoneyRails
  module ActiveRecord
    module PredicateBuilder
      class MoneyHandler
        def initialize(base_klass = nil)
          @base_klass = base_klass
        end

        def call(attribute, value)
          klass = base_klass || attribute.relation.engine

          subunit_name = klass.monetized_attributes[attribute.name]

          klass.arel_table[subunit_name].eq(value.cents)
        end

        private

        attr_reader :base_klass
      end
    end
  end
end
