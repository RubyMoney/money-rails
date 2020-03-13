module MoneyRails
  module ActiveRecord
    module MigrationExtensions
      module Table
        def money(accessor, options={})
          monetize(accessor, options)
        end

        def remove_money(accessor, options={})
          remove_monetize(accessor, options)
        end
      end
    end
  end
end
