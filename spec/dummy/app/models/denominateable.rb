if defined? Mongoid
  class Denominateable
    include Mongoid::Document

    field :unit, :type => Money::Currency
  end
end
