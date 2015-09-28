require "spec_helper"

describe "bundle install against gemstash" do
  let(:dir) { bundle_path(bundle) }

  def gem_dependencies(gems_param)
    results = []

    gems_param.split(",").each do |gem|
      case gem
      when "speaker"
        results << {
          :name => "speaker",
          :number => "0.1.0",
          :platform => "ruby",
          :dependencies => []
        }
      end
    end

    Marshal.dump results
  end

  before(:all) do
    @rubygems_server = SimpleServer.new("127.0.0.1")

    @rubygems_server.mount("/api/v1/dependencies") do |request, response|
      gems = request.query["gems"]

      if gems.nil? || gems.empty?
        response.status = 200
      else
        begin
          response.body = gem_dependencies(gems)
          response.content_type = "application/octet-stream"
          response.status = 200
        rescue
          response.body = "Error getting gem dependencies in '#{__FILE__}'"
          response.status = 500
        end
      end
    end

    @rubygems_server.mount("/gems/speaker-0.1.0.gem") do |_, response|
      response.status = 200
      response.content_type = "application/octet-stream"
      response.body = File.read(gem_path("speaker", "0.1.0"))
    end

    @rubygems_server.start
    @config = Gemstash::Configuration.new(config: {
                                            :base_path => TEST_BASE_PATH,
                                            :rubygems_url => @rubygems_server.url
                                          })
    Gemstash::Env.config = @config
    @gemstash = TestGemstashServer.new(port: 9042)
    @gemstash.start
  end

  after(:all) do
    @gemstash.stop
    @rubygems_server.stop
  end

  before do
    Gemstash::Env.config = @config
  end

  after do
    clean_bundle bundle
  end

  context "with just upstream gems" do
    let(:bundle) { "integration_spec/just_upstream_gems" }

    it "successfully bundles" do
      expect(execute("bundle", dir: dir)).to exit_success
      expect(execute("bundle exec speaker hi", dir: dir)).to exit_success.and_output("Hello world\n")
    end
  end

  context "with just private gems" do
    let(:bundle) { "integration_spec/just_private_gems" }

    it "successfully bundles"
  end

  context "with private and upstream gems" do
    let(:bundle) { "integration_spec/private_and_upstream_gems" }

    it "successfully bundles"
  end

  context "with private versions overriding upstream gems" do
    let(:bundle) { "integration_spec/private_overriding_upstream_gems" }

    it "successfully bundles"
  end
end
