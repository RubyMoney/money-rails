# frozen_string_literal: true

if defined? ActiveRecord
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
else
  # Mongoid eager-loads all models, so define some dummy methods for
  # models only used for ActiveRecord tests.
  class ApplicationRecord
    def self.register_currency(...) = nil
    def self.monetize(...) = nil
    def self.validates(...) = nil
  end
end
