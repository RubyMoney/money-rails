module MoneyRails
  module Monetizable
    class Railtie < ::Rails::Railtie
      initializer "moneyrails.initialize" do
        ActiveSupport.on_load(:active_record) do
          include MoneyRails::Monetizable
        end
      end
    end
  end
end
