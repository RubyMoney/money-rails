module MoneyRails
  class Railtie < ::Rails::Railtie
    initializer 'moneyrails.initialize', after: 'active_record.initialize_database' do
      MoneyRails::Hooks.init
    end
  end
end
