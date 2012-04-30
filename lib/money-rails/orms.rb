require "active_support/lazy_load_hooks"

# Thnx to Kristian Mandrup for the inspiration
# TODO: Include more ORMs/ODMs here

module MoneyRails
  module Orms
    def self.extend_for(name=:active_record)
      case name.to_sym
      when :active_record
        if defined?(ActiveRecord::Base)
          require "money-rails/active_record/monetizable"

          # Lazy load extension
          ActiveSupport.on_load :active_record do
            include MoneyRails::ActiveRecord::Monetizable
          end
        end
      else
        raise ArgumentError, "ORM extension for #{name} is currently not supported."
      end
    end

    # Return all supported ORMs
    def self.supported
      %w{active_record}
    end
  end
end
