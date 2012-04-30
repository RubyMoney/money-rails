module MoneyRails
  module Monetizable
    class Railtie < ::Rails::Railtie
      initializer "moneyrails.initialize" do
        MoneyRails::Orms.extend_for :active_record
      end
    end
  end
end
