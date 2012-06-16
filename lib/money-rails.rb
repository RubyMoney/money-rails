require "money"
require "money-rails/configuration"
require "money-rails/version"
require 'money-rails/hooks'

module MoneyRails
  extend Configuration
end

if defined? Rails
  require "money-rails/railtie"
end
