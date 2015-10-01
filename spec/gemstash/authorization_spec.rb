require "spec_helper"

describe Gemstash::Authorization do
  describe "#authorize" do
    context "with invalid permissions" do
      it "raises an error" do
        expect { Gemstash::Authorization.authorize("abc", nil) }.to raise_error(RuntimeError)
        expect { Gemstash::Authorization.authorize("abc", %w(invalid)) }.to raise_error(RuntimeError)
      end
    end

    context "with 'all' permission along with other permissions" do
      it "raises an error" do
        expect { Gemstash::Authorization.authorize("abc", %w(all yank)) }.to raise_error(RuntimeError)
      end
    end

    context "invalid authorization key" do
      it "raises an error" do
        expect { Gemstash::Authorization.authorize(nil, "all") }.to raise_error(RuntimeError)
        expect { Gemstash::Authorization.authorize("", "all") }.to raise_error(RuntimeError)
        expect { Gemstash::Authorization.authorize("  \t \n", "all") }.to raise_error(RuntimeError)
      end
    end

    context "valid authorization key and permissions" do
      it "inserts or updates the database" do
        Gemstash::Authorization.authorize("abc", "all")
        expect(Gemstash::Authorization["abc"].all?).to be_truthy
        Gemstash::Authorization.authorize("abc", %w(push yank))
        expect(Gemstash::Authorization["abc"].all?).to be_falsey
        expect(Gemstash::Authorization["abc"].push?).to be_truthy
        expect(Gemstash::Authorization["abc"].yank?).to be_truthy
      end
    end
  end

  describe "#[]" do
    context "an invalid authorization key" do
      it "returns nil" do
        expect(Gemstash::Authorization[nil]).to eq(nil)
        expect(Gemstash::Authorization[""]).to eq(nil)
        expect(Gemstash::Authorization["  \t \n"]).to eq(nil)
      end
    end

    context "a missing authorization key" do
      it "returns nil" do
        expect(Gemstash::Authorization["missing-key"]).to eq(nil)
      end
    end

    context "a valid authorization key" do
      before do
        Gemstash::Authorization.authorize("valid-key", "all")
      end

      it "returns the specified auth" do
        expect(Gemstash::Authorization["valid-key"]).to be
      end
    end
  end

  describe "permissions" do
    context "'all' permissions" do
      it "has authorization to everything" do
        Gemstash::Authorization.authorize("abc", "all")
        auth = Gemstash::Authorization["abc"]
        expect(auth.all?).to be_truthy
        expect(auth.push?).to be_truthy
        expect(auth.yank?).to be_truthy
        expect(auth.unyank?).to be_truthy
      end
    end

    context "a mix of permissions" do
      it "has authorization for given auths" do
        Gemstash::Authorization.authorize("abc", %w(push yank))
        auth = Gemstash::Authorization["abc"]
        expect(auth.all?).to be_falsey
        expect(auth.push?).to be_truthy
        expect(auth.yank?).to be_truthy
        expect(auth.unyank?).to be_falsey

        Gemstash::Authorization.authorize("abc", %w(yank unyank))
        auth = Gemstash::Authorization["abc"]
        expect(auth.all?).to be_falsey
        expect(auth.push?).to be_falsey
        expect(auth.yank?).to be_truthy
        expect(auth.unyank?).to be_truthy
      end
    end
  end
end
