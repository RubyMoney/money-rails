module MoneyRails
  module ActiveRecord
    module ModelExtensions
      class MonetizableAttribute
        attr_accessor :field, :options

        def initialize(field, options)
          @options = options
          @field = field
        end

        def deprecated?
          options[:field_currency] || options[:target_name] || options[:model_currency]
        end

        def subunit_name
          field.to_s
        end

        def field_currency_name
          # This attribute allows per column currency values
          # Overrides row and default currency
          options[:with_currency] || options[:field_currency] || nil
        end

        def instance_currency_name
          # Optional accessor to be run on an instance to detect currency
          name = options[:with_model_currency] ||
            options[:model_currency] || column_name
          name && name.to_s
        end

        def name
          return @name if @name

          @name = options[:as] || options[:target_name] || nil

          # Form target name for the money backed ActiveModel field:
          # if a target name is provided then use it
          # if there is a "{column.postfix}" suffix then just remove it to create the target name
          # if none of the previous is the case then use a default suffix
          @name = if @name
            @name.to_s
          elsif subunit_name =~ /#{postfix}$/
            subunit_name.sub(/#{postfix}$/, "")
          else
            # FIXME: provide a better default
            [subunit_name, "money"].join("_")
          end
        end

        def validation_enabled?
          MoneyRails.include_validations && !options[:disable_validation]
        end

        private

        def column_name
          @column_name ||= MoneyRails::Configuration.currency_column[:column_name]
        end

        def postfix
          @postfix ||= MoneyRails::Configuration.amount_column[:postfix]
        end
      end
    end
  end
end
