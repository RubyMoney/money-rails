module MoneyRails
  class Hooks
    def self.init
      # For Active Record
      ActiveSupport.on_load(:active_record) do
        require 'money-rails/active_model/validator'
        require 'money-rails/active_record/monetizable'
        ::ActiveRecord::Base.send :include, MoneyRails::ActiveRecord::Monetizable

        %w{options_extractor schema_statements table}.each { |file| require "money-rails/active_record/migration_extensions/#{file}" }
        ::ActiveRecord::Migration.send :include, MoneyRails::ActiveRecord::MigrationExtensions::SchemaStatements
        ::ActiveRecord::ConnectionAdapters::TableDefinition.send :include, MoneyRails::ActiveRecord::MigrationExtensions::Table
        ::ActiveRecord::ConnectionAdapters::Table.send :include, MoneyRails::ActiveRecord::MigrationExtensions::Table
      end

      # For Mongoid
      begin; require 'mongoid'; require 'mongoid/version'; rescue LoadError; end
      if defined? ::Mongoid
        if ::Mongoid::VERSION =~ /^2(.*)/
          require 'money-rails/mongoid/two' # Loading the file is enough
        end

        if ::Mongoid::VERSION =~ /^3(.*)/
          require 'money-rails/mongoid/three'
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
