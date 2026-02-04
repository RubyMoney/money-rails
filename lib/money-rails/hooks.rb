# frozen_string_literal: true

module MoneyRails
  class Hooks
    PG_ADAPTERS = %w[activerecord-jdbcpostgresql-adapter postgresql postgis].freeze

    def self.init
      # For Active Record
      ActiveSupport.on_load(:active_record) do
        require "money-rails/active_model/validator"
        require "money-rails/active_record/monetizable"
        ::ActiveRecord::Base.include(MoneyRails::ActiveRecord::Monetizable)

        current_adapter = ::ActiveRecord::Base.connection_db_config.configuration_hash[:adapter]
        postgresql_with_money = PG_ADAPTERS.include?(current_adapter)

        require "money-rails/active_record/migration_extensions/options_extractor"
        %w[schema_statements table].each do |file|
          require "money-rails/active_record/migration_extensions/#{file}_pg"
          unless postgresql_with_money
            require "money-rails/active_record/migration_extensions/#{file}"
          end
        end
        ::ActiveRecord::Migration.include(MoneyRails::ActiveRecord::MigrationExtensions::SchemaStatements)
        ::ActiveRecord::ConnectionAdapters::TableDefinition.include(MoneyRails::ActiveRecord::MigrationExtensions::Table)
        ::ActiveRecord::ConnectionAdapters::Table.include(MoneyRails::ActiveRecord::MigrationExtensions::Table)
      end

      # For Mongoid
      begin
        require "mongoid"
        require "mongoid/version"
      rescue LoadError
        # Do nothing
      end

      if defined? ::Mongoid
        require "money-rails/mongoid/money"
      end

      # For ActionView
      ActiveSupport.on_load(:action_view) do
        ::ActionView::Base.include MoneyRails::ActionViewExtension
      end

      # For ActiveSupport
      ActiveSupport.on_load(:active_job) do
        if defined?(::ActiveJob::Serializers)
          require "money-rails/active_job/money_serializer"
          Rails.application.config.active_job.tap do |config|
            config.custom_serializers ||= []
            config.custom_serializers << MoneyRails::ActiveJob::MoneySerializer
          end
        end
      end
    end
  end
end
