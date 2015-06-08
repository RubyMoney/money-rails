if defined? Mongoid
  class Priceable
    include Mongoid::Document

    field :price, :type => Money, :allow_nil => true
    field :price_hash, :type => Hash
  end
end
