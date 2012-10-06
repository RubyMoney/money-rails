class Money
  include ActiveModel::Serializers::JSON
  include ActiveModel::Serializers::Xml

  def attributes
    { 
      cents: cents, 
      to_s: self.to_s,
      currency: currency
    }
  end  

  class Currency
    include ActiveModel::Serializers::JSON
    include ActiveModel::Serializers::Xml    

    def attributes
      {
        id: id, 
        priority: priority, 
        thousands_separator: thousands_separator, 
        html_entity: html_entity, 
        decimal_mark: decimal_mark, 
        name: name, 
        symbol: symbol, 
        subunit_to_unit: subunit_to_unit, 
        iso_code: iso_code, 
        iso_numeric: iso_numeric, 
        subunit: subunit
      }
    end
  end

end