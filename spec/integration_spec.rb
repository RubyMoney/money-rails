require "spec_helper"

xdescribe "bundle install against gemstash" do
  let(:dir) { bundle_path(bundle) }

  before(:all) do
    @gemstash = TestGemstashServer.new(port: 9042)
    @gemstash.start
    @rubygems_server = SimpleServer.new("127.0.0.1")
    @rubygems_server.start
  end

  after(:all) do
    @gemstash.stop
    @rubygems_server.stop
  end

  before do
    config = Gemstash::Configuration.new(config: {
                                           :base_path => TEST_BASE_PATH,
                                           :rubygems_url => @rubygems_server.url
                                         })
    Gemstash::Env.config = config
  end

  after do
    clean_bundle bundle
  end

  context "with just cached gems" do
    let(:bundle) { "integration_spec/speaker" }

    it "successfully bundles" do
      expect(execute("bundle", dir: dir)).to exit_success
      expect(execute("bundle exec speaker hi", dir: dir)).to exit_success.and_output("Hello world\n")
    end
  end

  context "with just private gems" do
    it "successfully bundles"
  end

  context "with private and cached gems" do
    it "successfully bundles"
  end

  context "with private versions overriding public gems" do
    it "successfully bundles"
  end
end
