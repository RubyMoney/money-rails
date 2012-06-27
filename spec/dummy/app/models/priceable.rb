if defined? Mongoid
  class Priceable
    include Mongoid::Document

    field :price, :type => Money
  end
end
