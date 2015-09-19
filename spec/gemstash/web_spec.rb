require "spec_helper"
require "rack/test"

describe Gemstash::Web do
  include Rack::Test::Methods
  let(:app) { Gemstash::Web.new }

  context "GET /" do
    let(:request) { "/" }

    it "redirects to rubygems.org" do
      get request

      expect(last_response).to redirect_to("https://www.rubygems.org")
    end
  end
end
