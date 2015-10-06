require "spec_helper"

describe "bundle install against gemstash" do
  let(:dir) { bundle_path(bundle) }

  before(:all) do
    speaker_deps = {
      :name => "speaker",
      :number => "0.1.0",
      :platform => "ruby",
      :dependencies => []
    }

    @rubygems_server = SimpleServer.new("127.0.0.1", port: 9043)
    @rubygems_server.mount_gem_deps("speaker", [speaker_deps])
    @rubygems_server.mount_gem("speaker", "0.1.0")
    @rubygems_server.start
    @empty_server = SimpleServer.new("127.0.0.1", port: 9044)
    @empty_server.mount_gem_deps
    @empty_server.start
    @gemstash = TestGemstashServer.new(port: 9042,
                                       config: {
                                         :base_path => TEST_BASE_PATH,
                                         :rubygems_url => @rubygems_server.url
                                       })
    @gemstash.start
    @gemstash_empty_rubygems = TestGemstashServer.new(port: 9041,
                                                      config: {
                                                        :base_path => TEST_BASE_PATH,
                                                        :rubygems_url => @empty_server.url
                                                      })
    @gemstash_empty_rubygems.start
  end

  after(:all) do
    @gemstash.stop
    @gemstash_empty_rubygems.stop
    @rubygems_server.stop
    @empty_server.stop
  end

  after do
    clean_bundle bundle
  end

  context "with default upstream gems" do
    let(:bundle) { "integration_spec/default_upstream_gems" }

    it "successfully bundles" do
      expect(execute("bundle", dir: dir)).to exit_success
      expect(execute("bundle exec speaker hi", dir: dir)).to exit_success.and_output("Hello world\n")
    end
  end

  context "with upstream gems via a header mirror" do
    let(:bundle) { "integration_spec/header_mirror_gems" }

    # This should stay skipped until bundler sends the X-Gemfile-Source header
    xit "successfully bundles" do
      expect(execute("bundle", dir: dir)).to exit_success
      expect(execute("bundle exec speaker hi", dir: dir)).to exit_success.and_output("Hello world\n")
    end
  end

  context "with upstream gems" do
    let(:bundle) { "integration_spec/upstream_gems" }

    it "successfully bundles" do
      expect(execute("bundle", dir: dir)).to exit_success
      expect(execute("bundle exec speaker hi", dir: dir)).to exit_success.and_output("Hello world\n")
    end

    it "can successfully bundle twice" do
      expect(execute("bundle", dir: dir)).to exit_success
      expect(execute("bundle exec speaker hi", dir: dir)).to exit_success.and_output("Hello world\n")

      clean_bundle bundle

      expect(execute("bundle", dir: dir)).to exit_success
      expect(execute("bundle exec speaker hi", dir: dir)).to exit_success.and_output("Hello world\n")
    end
  end

  context "with redirecting gems" do
    let(:bundle) { "integration_spec/redirecting_gems" }

    it "successfully bundles" do
      expect(execute("bundle", dir: dir)).to exit_success
      expect(execute("bundle exec speaker hi", dir: dir)).to exit_success.and_output("Hello world\n")
    end
  end

  context "with private gems", :db_transaction => false do
    before do
      Gemstash::Authorization.authorize("test-key", "all")
      gem_contents = File.read(gem_path("speaker", "0.1.0"))
      Gemstash::GemPusher.new("test-key", gem_contents).push
    end

    let(:bundle) { "integration_spec/private_gems" }

    it "successfully bundles" do
      expect(execute("bundle", dir: dir)).to exit_success
      expect(execute("bundle exec speaker hi", dir: dir)).to exit_success.and_output("Hello world\n")
    end
  end
end
