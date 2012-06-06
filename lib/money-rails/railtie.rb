module MoneyRails
  module Monetizable
    ActiveSupport.on_load(:active_record) do
      MoneyRails::Orms.extend_for :active_record
    end
  end
end
