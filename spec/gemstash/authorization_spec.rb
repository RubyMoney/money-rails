# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gemstash::Authorization do
  describe "#remove" do
    context "with an existing authoriation" do
      before do
        Gemstash::Authorization.authorize("abc", "all")
      end

      it "removes the authorization" do
        # Fetch it first so caching invalidation is tested
        expect(Gemstash::Authorization["abc"]).to be
        Gemstash::Authorization.remove("abc")
        expect(Gemstash::Authorization["abc"]).to be_nil
        expect(the_log).to include("Authorization 'abc' with access to 'all' removed")
      end
    end

    context "with a non-existent authorization" do
      it "doesn't log the lack of removal" do
        Gemstash::Authorization.remove("non-existent")
        expect(the_log).to_not include("non-existent")
      end
    end

    context "with an invalid authorization" do
      it "raises an error" do
        expect { Gemstash::Authorization.authorize(nil, "all") }.to raise_error(RuntimeError)
        expect { Gemstash::Authorization.authorize("", "all") }.to raise_error(RuntimeError)
        expect { Gemstash::Authorization.authorize("  \t \n", "all") }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#authorize" do
    context "with invalid permissions" do
      it "raises an error" do
        expect { Gemstash::Authorization.authorize("abc", nil) }.to raise_error(RuntimeError)
        expect { Gemstash::Authorization.authorize("abc", %w[invalid]) }.to raise_error(RuntimeError)
      end
    end

    context "with 'all' permission along with other permissions" do
      it "raises an error" do
        expect { Gemstash::Authorization.authorize("abc", %w[all yank]) }.to raise_error(RuntimeError)
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
        expect(the_log).to include("Authorization 'abc' updated with access to 'all'")
        Gemstash::Authorization.authorize("abc", %w[push yank])
        expect(Gemstash::Authorization["abc"].all?).to be_falsey
        expect(Gemstash::Authorization["abc"].push?).to be_truthy
        expect(Gemstash::Authorization["abc"].yank?).to be_truthy
        expect(the_log).to include("Authorization 'abc' updated with access to 'push,yank'")
      end
    end
  end

  describe "#check" do
    context "with an invalid permission" do
      before do
        Gemstash::Authorization.authorize("abc", "all")
      end

      it "raises an error" do
        expect { Gemstash::Authorization.check("abc", "invalid") }.to raise_error(RuntimeError)
      end
    end

    context "with an empty authorization" do
      it "raises a Gemstash::NotAuthorizedError" do
        expect { Gemstash::Authorization.check(nil, "push") }.to raise_error(Gemstash::NotAuthorizedError, /key required/)
        expect { Gemstash::Authorization.check("", "push") }.to raise_error(Gemstash::NotAuthorizedError, /key required/)
        expect { Gemstash::Authorization.check("  \t\n ", "push") }.
          to raise_error(Gemstash::NotAuthorizedError, /key required/)
      end
    end

    context "with an invalid auth key" do
      it "raises a Gemstash::NotAuthorizedError" do
        expect { Gemstash::Authorization.check("invalid", "push") }.
          to raise_error(Gemstash::NotAuthorizedError, /key is invalid/)
      end
    end

    context "with an auth key without permission" do
      before do
        Gemstash::Authorization.authorize("abc", %w[yank])
      end

      it "raises a Gemstash::NotAuthorizedError" do
        expect { Gemstash::Authorization.check("abc", "push") }.
          to raise_error(Gemstash::NotAuthorizedError, /key doesn't have push access/)
      end
    end

    context "with an auth key with permission" do
      before do
        Gemstash::Authorization.authorize("abc", %w[push])
      end

      it "doesn't raise an error" do
        Gemstash::Authorization.check("abc", "push")
      end
    end

    context "with an auth key with all permissions" do
      before do
        Gemstash::Authorization.authorize("abc", "all")
      end

      it "doesn't raise an error" do
        Gemstash::Authorization.check("abc", "push")
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
        expect(auth.fetch?).to be_truthy
      end
    end

    context "a mix of permissions" do
      it "has authorization for given auths" do
        Gemstash::Authorization.authorize("abc", %w[push yank])
        auth = Gemstash::Authorization["abc"]
        expect(auth.all?).to be_falsey
        expect(auth.push?).to be_truthy
        expect(auth.yank?).to be_truthy
        expect(auth.fetch?).to be_falsey

        Gemstash::Authorization.authorize("abc", %w[yank fetch])
        auth = Gemstash::Authorization["abc"]
        expect(auth.all?).to be_falsey
        expect(auth.push?).to be_falsey
        expect(auth.yank?).to be_truthy
        expect(auth.fetch?).to be_truthy
      end
    end
  end
end
