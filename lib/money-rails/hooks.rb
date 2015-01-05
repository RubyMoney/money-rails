module MoneyRails
  class Hooks
    def self.init
      # For Active Record
      ActiveSupport.on_load(:active_record) do
        require 'money-rails/active_model/validator'
        require 'money-rails/active_record/monetizable'
        ::ActiveRecord::Base.send :include, MoneyRails::ActiveRecord::Monetizable
        if ::Rails::VERSION::MAJOR >= 4
          rails42               = case
                                  when ::Rails::VERSION::MAJOR < 5 && ::Rails::VERSION::MINOR >= 2
                                    true
                                  when ::Rails::VERSION::MAJOR >= 5
                                    true
                                  else
                                    false
                                  end
          postgresql_with_money = rails42 && ['activerecord-jdbcpostgresql-adapter', 'postgresql'].include?(::ActiveRecord::Base.connection.instance_values["config"][:adapter])
        end

        require "money-rails/active_record/migration_extensions/options_extractor"
        %w{schema_statements table}.each do |file|
          if postgresql_with_money
            require "money-rails/active_record/migration_extensions/#{file}_pg_rails4"
          else
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
