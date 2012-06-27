DatabaseCleaner[:active_record].strategy = :transaction if defined? ActiveRecord
DatabaseCleaner[:mongoid].strategy = :truncation if defined? Mongoid

RSpec.configure do |config|
  config.before :suite do
    DatabaseCleaner.clean_with :truncation
  end
  config.before :each do
    DatabaseCleaner.start
  end
  config.after :each do
    DatabaseCleaner.clean
  end
end
