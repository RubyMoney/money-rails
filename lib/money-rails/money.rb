require "active_support/core_ext/module/aliasing.rb"
require "active_support/core_ext/hash/reverse_merge.rb"

class Money
  alias_method :orig_format, :format

  def format(*rules)
    rules = normalize_formatting_rules(rules)

    # Apply global defaults for money only for non-nil values
    defaults = {
      no_cents_if_whole: MoneyRails::Configuration.no_cents_if_whole,
      symbol: MoneyRails::Configuration.symbol,
      sign_before_symbol: MoneyRails::Configuration.sign_before_symbol
    }.reject { |_k, v| v.nil? }

    rules.reverse_merge!(defaults)

    unless MoneyRails::Configuration.default_format.nil?
      rules.reverse_merge!(MoneyRails::Configuration.default_format)
    end

    orig_format(rules)
  end

end
