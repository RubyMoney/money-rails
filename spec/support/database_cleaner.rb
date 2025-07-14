
RSpec.configure do |config|
  config.before :suite do
    if defined? ActiveRecord
      DatabaseCleaner.strategy = :transaction
    elsif defined? Mongoid
      DatabaseCleaner.strategy = :truncation
    end

    DatabaseCleaner.clean_with :truncation
  end
  config.before :each do
    DatabaseCleaner.start
  end
  config.after :each do
    DatabaseCleaner.clean
  end
end
