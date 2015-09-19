require "spec_helper"

describe Gemstash::Dependencies do
  let(:web_helper) { double }
  let(:deps) { Gemstash::Dependencies.new(web_helper) }

  def valid_url(url, expected_gems)
    expect(url).to start_with("/api/v1/dependencies?gems=")
    params = url.sub("/api/v1/dependencies?gems=", "")
    expect(params.split(",")).to match_array(expected_gems)
  end

  describe ".fetch" do
    context "one gem" do
      it "finds the gem" do
        result = [{
          :name         => "foo",
          :number       => "1.0.0",
          :platform     => "ruby",
          :dependencies => []
        }]

        expect(web_helper).to receive(:get) {|url|
          valid_url(url, %w(foo))
          Marshal.dump(result)
        }

        expect(deps.fetch(%w(foo))).to eq(result)
      end
    end

    context "multiple gems" do
      it "finds the gems" do
        result = [{
          :name         => "foo",
          :number       => "1.0.0",
          :platform     => "ruby",
          :dependencies => []
        }, {
          :name         => "bar",
          :number       => "1.0.0",
          :platform     => "ruby",
          :dependencies => []
        }]

        expect(web_helper).to receive(:get) {|url|
          valid_url(url, %w(foo bar))
          Marshal.dump(result)
        }

        expect(deps.fetch(%w(foo bar))).to match_array(result)
      end
    end

    context "some missing gems" do
      it "finds the available gems" do
        result = [{
          :name         => "foo",
          :number       => "1.0.0",
          :platform     => "ruby",
          :dependencies => []
        }, {
          :name         => "bar",
          :number       => "1.0.0",
          :platform     => "ruby",
          :dependencies => []
        }]

        expect(web_helper).to receive(:get) {|url|
          valid_url(url, %w(foo bar baz))
          Marshal.dump(result)
        }

        expect(deps.fetch(%w(foo bar baz))).to match_array(result)
      end
    end

    context "multiple similar requests" do
      it "caches the results" do
        foo = {
          :name         => "foo",
          :number       => "1.0.0",
          :platform     => "ruby",
          :dependencies => []
        }

        bar = {
          :name         => "bar",
          :number       => "1.0.0",
          :platform     => "ruby",
          :dependencies => []
        }

        expect(web_helper).to receive(:get) {|url|
          valid_url(url, %w(foo bar baz))
          Marshal.dump([foo, bar])
        }.once

        expect(deps.fetch(%w(foo bar baz))).to match_array([foo, bar])
        expect(deps.fetch(%w(baz foo bar))).to match_array([foo, bar])
      end
    end
  end
end
