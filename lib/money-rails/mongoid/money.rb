class Money

  # Converts an object of this instance into a database friendly value.
  def mongoize
    {
      cents:        cents.mongoize.to_f,
      currency_iso: currency.iso_code.mongoize
    }
  end

  class << self

    # Get the object as it was stored in the database, and instantiate
    # this custom class from it.
    def demongoize(object)
      return nil unless object.is_a?(Hash)

      object = object.symbolize_keys
      return nil unless object.has_key?(:cents)

      Money.new(object[:cents], object[:currency_iso])
    end

    # Takes any possible object and converts it to how it would be
    # stored in the database.
    def mongoize(object)
      return object.mongoize if object.is_a?(Money)
      return mongoize_hash(object) if object.is_a?(Hash)
      return nil if object.nil?
      return mongoize_castable(object) if object.respond_to?(:to_money)

      # QUESTION: why whould we even want to store it?
      # Perhaps we should raise an error when such unknown object is given.
      object
    end

    # Converts the object that was supplied to a criteria and converts it
    # into a database friendly form.
    def evolve(object)
      case object
      when Money then object.mongoize
      else object
      end
    end

    private

    def mongoize_hash(hash)
      hash = hash.symbolize_keys

      # Guard for a blank form
      return nil if hash[:cents] == '' && hash[:currency_iso] == ''

      # QUESTION: what if Money::Currency::UnknownCurrency will be raised?
      # Should it be dependent on `MoneyRails.raise_error_on_money_parsing`?
      Money.new(hash[:cents], hash[:currency_iso]).mongoize
    end

    def mongoize_castable(object)
      object.to_money.mongoize
    rescue Money::Currency::UnknownCurrency, Monetize::ParseError => error
      return nil unless MoneyRails.raise_error_on_money_parsing

      raise MoneyRails::Error, error.message
    end
  end
end
