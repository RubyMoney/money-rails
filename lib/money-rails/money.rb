require "active_support/core_ext/module/aliasing.rb"
require "active_support/core_ext/hash/reverse_merge.rb"

class Money
  class << self
    alias_method :orig_default_formatting_rules, :default_formatting_rules

    # Temporarily sets the default bank for Money operations within the block
    #
    # @param bank [Money::Bank] the bank to use temporarily
    # @yield the block to execute with the temporary bank
    # @return [Object] the return value of the yielded block
    #
    def with_bank(bank)
      old_bank, ::Money.default_bank = ::Money.default_bank, bank
      yield
    ensure
      ::Money.default_bank = old_bank
    end

    def default_formatting_rules
      rules = orig_default_formatting_rules || {}
      defaults = {
        no_cents_if_whole: MoneyRails::Configuration.no_cents_if_whole,
        symbol: MoneyRails::Configuration.symbol,
        sign_before_symbol: MoneyRails::Configuration.sign_before_symbol
      }.reject { |_k, v| v.nil? }

      rules.reverse_merge!(defaults)

      unless MoneyRails::Configuration.default_format.nil?
        rules.reverse_merge!(MoneyRails::Configuration.default_format)
      end
      rules
    end
  end

  # This is expected to be called by ActiveSupport when calling as_json an Money object
  def to_hash
    { cents: cents, currency_iso: currency.iso_code.to_s }
  end
end
