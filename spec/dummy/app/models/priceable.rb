if defined? Mongoid
  class Priceable
    include Mongoid::Document

    field :price, :type => Money
    field :price_hash, :type => Hash
  end
end
