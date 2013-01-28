require "active_support/core_ext/module/aliasing.rb"
require "active_support/core_ext/hash/reverse_merge.rb"

class Money

  def format_with_settings(*rules)
    rules = normalize_formatting_rules(rules)

    # Apply global defaults for money only for non-nil values
    # TODO: Add here more setting options
    defaults = {
      no_cents_if_whole: MoneyRails::Configuration.no_cents_if_whole,
      symbol: MoneyRails::Configuration.symbol
    }.reject { |k,v| v.nil? }

    rules.reverse_merge!(defaults)

    format_without_settings(rules)
  end

  alias_method_chain :format, :settings

end
