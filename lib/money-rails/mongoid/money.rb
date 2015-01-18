class Money

  # Converts an object of this instance into a database friendly value.
  def mongoize
    {
      :cents        => cents.mongoize.to_f,
      :currency_iso => currency.iso_code.mongoize
    }
  end

  class << self

    # Get the object as it was stored in the database, and instantiate
    # this custom class from it.
    def demongoize(object)
      if object.is_a?(Hash)
        if object.respond_to?(:deep_symbolize_keys)
          object = object.deep_symbolize_keys
        else
          object = object.symbolize_keys
        end
        object.has_key?(:cents) ? ::Money.new(object[:cents], object[:currency_iso]) : nil
      else
        nil
      end
    end

    # Takes any possible object and converts it to how it would be
    # stored in the database.
    def mongoize(object)
      case
      when object.is_a?(Money) then object.mongoize
      when object.is_a?(Hash) then
        if object.respond_to?(:deep_symbolize_keys!)
          object.deep_symbolize_keys!
        elsif object.respond_to?(:symbolize_keys!)
          object.symbolize_keys!
        end
        ::Money.new(object[:cents], object[:currency_iso]).mongoize
      when object.respond_to?(:to_money) then
        begin
          object.to_money.mongoize
        rescue ArgumentError, Money::Currency::UnknownCurrency
          raise if MoneyRails.raise_error_on_money_parsing
          nil
        end
      else object
      end
    end

    # Converts the object that was supplied to a criteria and converts it
    # into a database friendly form.
    def evolve(object)
      case object
      when Money then object.mongoize
      else object
      end
    end
  end
end
