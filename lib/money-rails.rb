# frozen_string_literal: true

require "active_support/lazy_load_hooks"
require "money"
require "monetize"
require "monetize/core_extensions"
require "money-rails/configuration"
require "money-rails/money"
require "money-rails/version"
require "money-rails/hooks"
require "money-rails/errors"

module MoneyRails
  autoload :ActionViewExtension, "money-rails/helpers/action_view_extension"

  extend Configuration
end

# Registering the hooks here, rather than in the railtie initializer, keeps the
# integration points visible without a full Rails boot. Registration is lazy: the
# blocks only run once the framework in question is loaded.
ActiveSupport.on_load(:active_record) do
  require "money-rails/active_model/validator"
  require "money-rails/active_record/monetizable"
  ActiveRecord::Base.include(MoneyRails::ActiveRecord::Monetizable)
end

ActiveSupport.on_load(:action_view) do
  ActionView::Base.include MoneyRails::ActionViewExtension
end

if defined? Rails::Railtie
  require "money-rails/railtie"
  require "money-rails/engine"
end

if Object.const_defined?("RailsAdmin")
  require "money-rails/rails_admin"
end
