require "money"
require "monetize"
require "monetize/core_extensions"
require "money-rails/configuration"
require "money-rails/money"
require "money-rails/version"
require 'money-rails/hooks'

module MoneyRails
  extend Configuration

  # We need our own instance of +ActiveSupport::Deprecation+, because otherwise
  # using the same singleton instance as Rails's could spill trouble.
  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new('2.0', 'Money-rails')
  end
end

if defined? Rails
  require "money-rails/railtie"
  require "money-rails/engine"
end
