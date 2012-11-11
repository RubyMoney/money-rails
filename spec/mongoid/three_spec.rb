require 'spec_helper'

if defined?(Mongoid) && ::Mongoid::VERSION =~ /^3(.*)/

  describe Money do
    let!(:priceable) { Priceable.create(:price => Money.new(100, 'EUR')) }

    context "mongoize" do
      it "mongoizes correctly a Money object to a hash of cents and currency" do
        priceable.price.cents.should == 100
        priceable.price.currency.should == Money::Currency.find('EUR')
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
        zero_priceable = Priceable.create(:price => 0)
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
