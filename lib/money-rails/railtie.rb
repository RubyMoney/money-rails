module MoneyRails
  class Railtie < ::Rails::Railtie
    initializer 'moneyrails.initialize' do
      MoneyRails::Hooks.init
    end
  end
end
