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
    case
    when object.is_a?(Money)
        {
          :cents        => object.cents,
          :currency_iso => object.currency.iso_code
        }
    when object.respond_to?(:to_money)
        serialize(object.to_money)
    else nil
    end
  end
end
