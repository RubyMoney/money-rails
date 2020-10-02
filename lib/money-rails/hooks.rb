module MoneyRails
  class Hooks
    PG_ADAPTERS = %w(activerecord-jdbcpostgresql-adapter postgresql postgis)

    def self.init
      # For Active Record
      ActiveSupport.on_load(:active_record) do
        require 'money-rails/active_model/validator'
        require 'money-rails/active_record/monetizable'
        ::ActiveRecord::Base.send :include, MoneyRails::ActiveRecord::Monetizable
        if defined?(::ActiveRecord) && defined?(::ActiveRecord::VERSION)
          if ::ActiveRecord::VERSION::MAJOR >= 4
            rails42               = case
                                    when ::ActiveRecord::VERSION::MAJOR < 5 && ::ActiveRecord::VERSION::MINOR >= 2
                                      true
                                    when ::ActiveRecord::VERSION::MAJOR >= 5
                                      true
                                    else
                                      false
                                    end

            current_adapter = if ::ActiveRecord::Base.respond_to?(:connection_db_config)
                                ::ActiveRecord::Base.connection_db_config.configuration_hash[:adapter]
                              else
                                ::ActiveRecord::Base.connection_config[:adapter]
                              end

            postgresql_with_money = rails42 && PG_ADAPTERS.include?(current_adapter)
          end
        end

        require "money-rails/active_record/migration_extensions/options_extractor"
        %w{schema_statements table}.each do |file|
          require "money-rails/active_record/migration_extensions/#{file}_pg_rails4"
          if !postgresql_with_money
            require "money-rails/active_record/migration_extensions/#{file}"
          end
        end
        ::ActiveRecord::Migration.send :include, MoneyRails::ActiveRecord::MigrationExtensions::SchemaStatements
        ::ActiveRecord::ConnectionAdapters::TableDefinition.send :include, MoneyRails::ActiveRecord::MigrationExtensions::Table
        ::ActiveRecord::ConnectionAdapters::Table.send :include, MoneyRails::ActiveRecord::MigrationExtensions::Table
      end

      # For Mongoid
      begin; require 'mongoid'; require 'mongoid/version'; rescue LoadError; end
      if defined? ::Mongoid
        if ::Mongoid::VERSION =~ /^2(.*)/
          require 'money-rails/mongoid/two' # Loading the file is enough
        else
          require 'money-rails/mongoid/money'
        end
      end

      # For ActionView
      ActiveSupport.on_load(:action_view) do
        require 'money-rails/helpers/action_view_extension'
        ::ActionView::Base.send :include, MoneyRails::ActionViewExtension
      end
    end
  end
end
