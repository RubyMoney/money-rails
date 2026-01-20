require "spec_helper"

if defined?(::ActiveJob::Serializers)
  describe MoneyRails::ActiveJob::MoneySerializer do
    let(:money) { Money.new(1_00, "EUR") }
    let(:serialized_money) do
      {
        "_aj_serialized" => "MoneyRails::ActiveJob::MoneySerializer",
        "cents" => 1_00,
        "currency" => "EUR",
      }
    end

    describe "#serialize?" do
      it { expect(described_class.serialize?(money)).to be_truthy }
      it { expect(described_class.serialize?(1_00)).not_to be_truthy }
    end

    describe "#serialize" do
      it { expect(described_class.serialize(money)).to eq(serialized_money) }
    end

    describe "#deserialize" do
      it { expect(described_class.deserialize(serialized_money)).to eq(money) }
    end
  end
end
