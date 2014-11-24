ENV["RAILS_ENV"] = 'test'
# Require dummy Rails app
require File.expand_path("../../spec/dummy/config/environment", __FILE__)

require 'database_cleaner'
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

# Silence warnings
if Money.respond_to?(:silence_core_extensions_deprecations=)
  Money.silence_core_extensions_deprecations = true
end

RSpec.configure do |config|
  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!
end
