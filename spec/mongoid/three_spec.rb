require 'spec_helper'

if defined?(Mongoid) && ::Mongoid::VERSION =~ /^3(.*)/

  describe Money do
    let!(:priceable) { Priceable.create(:price => Money.new(100, 'EUR')) }
    let!(:priceable_from_num) { Priceable.create(:price => 1) }
    let!(:priceable_from_string) { Priceable.create(:price => '1 EUR' )}

    context "mongoize" do
      it "mongoizes correctly a Money object to a hash of cents and currency" do
        priceable.price.cents.should == 100
        priceable.price.currency.should == Money::Currency.find('EUR')
      end

      it "mongoizes correctly a Numeric object to a hash of cents and currency" do
        priceable_from_num.price.cents.should == 100
        priceable_from_num.price.currency.should == Money.default_currency
      end

      it "mongoizes correctly a String object to a hash of cents and currency" do
        priceable_from_string.price.cents.should == 100
        priceable_from_string.price.currency.should == Money::Currency.find('EUR')
      end
    end

    context "demongoize" do
      subject { Priceable.first.price }
      it { should be_an_instance_of(Money) }
      it { should == Money.new(100, 'EUR') }
      it "returns nil if a nil value was stored" do
        nil_priceable = Priceable.create(:price => nil)
        nil_priceable.price.should be_nil
      end
      it 'returns nil if an unknown value was stored' do
        zero_priceable = Priceable.create(:price => [])
        zero_priceable.price.should be_nil
      end
    end

    context "evolve" do
      it "transforms correctly a Money object to a Mongo friendly value" do
        Priceable.where(:price => Money.new(100, 'EUR')).first.should == priceable
      end
    end
  end
end
