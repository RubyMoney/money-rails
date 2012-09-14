# Class name does not really matches the folder hierarchy, because
# in order for (de)serialization to work, the class must be re-opened.
# But this file brings mongoid 2.X compat., so...

class Money
  include ::Mongoid::Fields::Serializable

  # Mongo friendly -> Money
  def deserialize(object)
    return nil if object.nil?

    object = object.with_indifferent_access
    ::Money.new object[:cents], object[:currency_iso]
  end

  # Money -> Mongo friendly
  def serialize(object)
    return nil unless object.is_a? Money

    {
      :cents        => object.cents,
      :currency_iso => object.currency.iso_code
    }
  end
end

class Money::Currency
  include ::Mongoid::Fields::Serializable

  # Mongo friendly -> Money::Currency
  def deserialize(object)
    return nil if object.nil?

    ::Money::Currency.find object
  end

  # Money::Currency -> Mongo friendly
  def serialize(object)
    return nil unless object.is_a? Money::Currency

    object.iso_code
  end
end


