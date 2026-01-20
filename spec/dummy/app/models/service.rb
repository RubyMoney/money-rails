# frozen_string_literal: true

class Service < ApplicationRecord
  monetize :charge_cents, with_currency: :usd

  monetize :discount_cents
end
