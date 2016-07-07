require "spec_helper"

describe Gemstash::Dependencies do
  let(:upstream) { "https://rubygems.org" }
  let(:http_client) { double }
  let(:web_deps) { Gemstash::Dependencies.for_upstream(upstream, http_client) }
  let(:db_deps) { Gemstash::Dependencies.for_private }

  def valid_url(url, expected_gems)
    expect(url).to start_with("api/v1/dependencies?gems=")
    params = url.sub("api/v1/dependencies?gems=", "")
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

        expect(http_client).to receive(:get) {|url|
          valid_url(url, %w(foo))
          Marshal.dump(result)
        }

        expect(web_deps.fetch(%w(foo))).to eq(result)
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

        expect(http_client).to receive(:get) {|url|
          valid_url(url, %w(foo bar))
          Marshal.dump(result)
        }

        expect(web_deps.fetch(%w(foo bar))).to match_dependencies(result)
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

        expect(http_client).to receive(:get) {|url|
          valid_url(url, %w(foo bar baz))
          Marshal.dump(result)
        }

        expect(web_deps.fetch(%w(foo bar baz))).to match_dependencies(result)
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

        expect(http_client).to receive(:get) {|url|
          valid_url(url, %w(foo bar baz))
          Marshal.dump([foo, bar])
        }.once

        expect(web_deps.fetch(%w(foo bar baz))).to match_dependencies([foo, bar])
        expect(web_deps.fetch(%w(baz foo bar))).to match_dependencies([foo, bar])
        expect(web_deps.fetch(%w(foo))).to match_dependencies([foo])
        expect(web_deps.fetch(%w(bar))).to match_dependencies([bar])
        expect(web_deps.fetch(%w(baz))).to match_dependencies([])
      end
    end

    context "with private gem requests" do
      before do
        gem_id = insert_rubygem "custom"
        version_id = insert_version gem_id, "0.0.1"
        insert_dependency version_id, "foo", "~> 1.0"
      end

      it "finds the available gems" do
        custom = {
          :name         => "custom",
          :number       => "0.0.1",
          :platform     => "ruby",
          :dependencies => [["foo", "~> 1.0"]]
        }

        expect(db_deps.fetch(%w(foo bar baz custom))).to match_dependencies([custom])
      end
    end

    context "with multiple private gem requests" do
      before do
        gem1_id = insert_rubygem "custom1"
        gem2_id = insert_rubygem "custom2"
        version1_id = insert_version gem1_id, "0.0.1"
        insert_version gem2_id, "0.2.0"
        version2_id = insert_version gem1_id, "0.2.1"
        insert_dependency version1_id, "foo", "~> 1.0"
        insert_dependency version2_id, "foo", "~> 1.1"
        insert_dependency version1_id, "bar", ">= 0.9"
      end

      def dependency_item(results, name, number)
        results.find {|x| x[:name] == name && x[:number] == number }
      end

      it "finds the available gems" do
        custom1_0_0_1 = {
          :name         => "custom1",
          :number       => "0.0.1",
          :platform     => "ruby",
          :dependencies => [["foo", "~> 1.0"],
                            ["bar", ">= 0.9"]]
        }

        custom1_0_2_1 = {
          :name         => "custom1",
          :number       => "0.2.1",
          :platform     => "ruby",
          :dependencies => [["foo", "~> 1.1"]]
        }

        custom2 = {
          :name         => "custom2",
          :number       => "0.2.0",
          :platform     => "ruby",
          :dependencies => []
        }

        expect(db_deps.fetch(%w(custom1 custom2))).
          to match_dependencies([custom1_0_0_1, custom1_0_2_1, custom2])
      end
    end
  end
end
