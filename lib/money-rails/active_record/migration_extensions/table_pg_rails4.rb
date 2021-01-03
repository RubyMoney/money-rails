module MoneyRails
  module ActiveRecord
    module MigrationExtensions
      module Table
        def monetize(accessor, options={})
          [:amount, :currency].each do |attribute|
            column_present, _, *opts = OptionsExtractor.extract attribute, :no_table, accessor, options
            if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3')
              constraints = opts.pop
              column(*opts, options: constraints) if column_present
            else
              column(*opts) if column_present
            end
          end
        end

        def remove_monetize(accessor, options={})
          [:amount, :currency].each do |attribute|
            column_present, _, column_name, _, _ =  OptionsExtractor.extract attribute, :no_table, accessor, options
            remove column_name if column_present
          end
        end
      end
    end
  end
end
