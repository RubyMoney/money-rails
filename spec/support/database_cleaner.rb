# frozen_string_literal: true

RSpec.configure do |config|
  config.before :suite do
    if defined?(Mongoid)
      DatabaseCleaner[:mongoid].clean_with :deletion
      DatabaseCleaner[:mongoid].strategy = :deletion
    else
      DatabaseCleaner[:active_record].clean_with :truncation
      DatabaseCleaner[:active_record].strategy = :transaction
    end
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end
