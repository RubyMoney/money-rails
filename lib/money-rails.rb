require "money"
require "monetize"
require "monetize/core_extensions"
require "money-rails/configuration"
require "money-rails/money"
require "money-rails/version"
require 'money-rails/hooks'
require 'money-rails/errors'

module MoneyRails
  extend Configuration
end

if defined? ::Rails::Railtie
  require "money-rails/railtie"
  require "money-rails/engine"
end

if Object.const_defined?("RailsAdmin")
  require "money-rails/rails_admin"
end
