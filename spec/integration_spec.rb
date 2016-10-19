require "spec_helper"
require "fileutils"

describe "gemstash integration tests" do
  let(:auth) { Gemstash::ApiKeyAuthorization.new(auth_key) }
  let(:auth_key) { "test-key" }

  before(:all) do
    speaker_deps = [
      {
        :name => "speaker",
        :number => "0.1.0",
        :platform => "ruby",
        :dependencies => []
      }, {
        :name => "speaker",
        :number => "0.1.0",
        :platform => "java",
        :dependencies => []
      }, {
        :name => "speaker",
        :number => "0.2.0.pre",
        :platform => "ruby",
        :dependencies => []
      }, {
        :name => "speaker",
        :number => "0.2.0.pre",
        :platform => "java",
        :dependencies => []
      }
    ]

    speaker_specs = [["speaker", Gem::Version.new("0.1.0"), "ruby"],
                     ["speaker", Gem::Version.new("0.1.0"), "java"]]
    speaker_prerelease_specs = [["speaker", Gem::Version.new("0.2.0.pre"), "ruby"],
                                ["speaker", Gem::Version.new("0.2.0.pre"), "java"]]
    @rubygems_server = SimpleServer.new("127.0.0.1", port: 9043)
    @rubygems_server.mount_gem_deps("speaker", speaker_deps)
    @rubygems_server.mount_gem("speaker", "0.1.0")
    @rubygems_server.mount_gem("speaker", "0.1.0-java")
    @rubygems_server.mount_gem("speaker", "0.2.0.pre")
    @rubygems_server.mount_gem("speaker", "0.2.0.pre-java")
    @rubygems_server.mount_quick_marshal("speaker", "0.1.0")
    @rubygems_server.mount_quick_marshal("speaker", "0.1.0-java")
    @rubygems_server.mount_quick_marshal("speaker", "0.2.0.pre")
    @rubygems_server.mount_quick_marshal("speaker", "0.2.0.pre-java")
    @rubygems_server.mount_specs_marshal_gz(speaker_specs)
    @rubygems_server.mount_prerelease_specs_marshal_gz(speaker_prerelease_specs)
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

  describe "interacting with private gems" do
    let(:env_name) { "integration_spec/private_gems" }
    let(:env_dir) { env_path(env_name) }
    let(:host) { "#{@gemstash.url}/private" }
    let(:gem_name) { "speaker" }
    let(:gem) { gem_path(gem_name, gem_version) }
    let(:gem_version) { "0.1.0" }
    let(:gem_contents) { read_gem(gem_name, gem_version) }
    let(:deps) { Gemstash::Dependencies.for_private }
    let(:storage) { Gemstash::Storage.for("private").for("gems") }
    let(:http_client) { Gemstash::HTTPClient.for(@gemstash.private_upstream) }

    let(:speaker_deps) do
      {
        :name => "speaker",
        :number => "0.1.0",
        :platform => "ruby",
        :dependencies => []
      }
    end

    before do
      FileUtils.chmod(0600, File.join(env_dir, ".gem/credentials"))
      Gemstash::Authorization.authorize(auth_key, "all")
    end

    after do
      # Some actions affect files in the environment, like adding and removing sources
      clean_env env_name
    end

    context "pushing a gem" do
      before do
        expect(deps.fetch(%w(speaker))).to match_dependencies([])
        expect { storage.resource("speaker-0.1.0").content(:gem) }.to raise_error(RuntimeError)
        @gemstash.env.cache.flush
      end

      it "pushes valid gems to the server", db_transaction: false do
        env = { "HOME" => env_dir }
        expect(execute("gem", ["push", "--key", "test", "--host", host, gem], env: env)).to exit_success
        expect(deps.fetch(%w(speaker))).to match_dependencies([speaker_deps])
        expect(storage.resource("speaker-0.1.0").content(:gem)).to eq(gem_contents)
        expect(http_client.get("gems/speaker-0.1.0")).to eq(gem_contents)
      end
    end

    context "searching for a gem" do
      before do
        Gemstash::GemPusher.new(auth, gem_contents).serve
        expect(deps.fetch(%w(speaker))).to match_dependencies([speaker_deps])
        @gemstash.env.cache.flush
      end

      it "finds private gems", db_transaction: false do
        env = { "HOME" => env_dir }
        expect(execute("gem", ["search", "-ar", "speaker", "--clear-sources", "--source", host], env: env)).
          to exit_success.and_output(/speaker \(0.1.0\)/)
      end

      it "finds private gems when just the private source is configured", db_transaction: false do
        env = { "HOME" => env_dir }
        expect(execute("gem", ["source", "-r", "https://rubygems.org/"], env: env)).to exit_success
        expect(execute("gem", ["source", "-a", "#{host}/"], env: env)).to exit_success
        expect(execute("gem", ["search", "-ar", "speaker"], env: env)).
          to exit_success.and_output(/speaker \(0.1.0\)/)
      end

      it "finds private gems when just the private source is configured without a trailing slash", db_transaction: false do
        skip "this doesn't work because Rubygems sends /specs.4.8.gz instead of /private/specs.4.8.gz"
        env = { "HOME" => env_dir }
        expect(execute("gem", ["source", "-r", "https://rubygems.org/"], env: env)).to exit_success
        expect(execute("gem", ["source", "-a", host], env: env)).to exit_success
        expect(execute("gem", ["search", "-ar", "speaker"], env: env)).
          to exit_success.and_output(/speaker \(0.1.0\)/)
      end
    end

    context "yanking a gem" do
      before do
        Gemstash::GemPusher.new(auth, gem_contents).serve
        expect(deps.fetch(%w(speaker))).to match_dependencies([speaker_deps])
        @gemstash.env.cache.flush
      end

      it "removes valid gems from the server", db_transaction: false do
        env = { "HOME" => env_dir, "RUBYGEMS_HOST" => host }
        expect(execute("gem", ["yank", "--key", "test", gem_name, "--version", gem_version], env: env)).to exit_success
        expect(deps.fetch(%w(speaker))).to match_dependencies([])
        # It shouldn't actually delete the gem, to support unyank
        expect(storage.resource("speaker-0.1.0").content(:gem)).to eq(gem_contents)
        # But it should block downloading the yanked gem
        expect { http_client.get("gems/speaker-0.1.0") }.to raise_error(Gemstash::WebError)
      end
    end

    context "unyanking a gem" do
      before do
        Gemstash::GemPusher.new(auth, gem_contents).serve
        Gemstash::GemYanker.new(auth, gem_name, gem_version).serve
        expect(deps.fetch(%w(speaker))).to match_dependencies([])
        @gemstash.env.cache.flush
      end

      it "adds valid gems back to the server", db_transaction: false do
        env = { "HOME" => env_dir, "RUBYGEMS_HOST" => host }
        expect(execute("gem", ["yank", "--key", "test", gem_name, "--version", gem_version, "--undo"], env: env)).
          to exit_success
        expect(deps.fetch(%w(speaker))).to match_dependencies([speaker_deps])
        expect(storage.resource("speaker-0.1.0").content(:gem)).to eq(gem_contents)
        expect(http_client.get("gems/speaker-0.1.0")).to eq(gem_contents)
      end
    end
  end

  describe "bundle install against gemstash" do
    let(:dir) { bundle_path(bundle) }

    let(:platform_message) do
      if RUBY_PLATFORM == "java"
        "Java"
      else
        "Ruby"
      end
    end

    after do
      clean_bundle bundle
    end

    shared_examples "a bundleable project" do
      it "successfully bundles" do
        expect(execute("bundle", dir: dir)).to exit_success
        expect(execute("bundle", %w(exec speaker hi), dir: dir)).
          to exit_success.and_output("Hello world, #{platform_message}\n")
      end

      it "can bundle with full index" do
        expect(execute("bundle", %w(--full-index), dir: dir)).to exit_success
        expect(execute("bundle", %w(exec speaker hi), dir: dir)).
          to exit_success.and_output("Hello world, #{platform_message}\n")
      end

      it "can bundle with prerelease versions" do
        env = { "SPEAKER_VERSION" => "= 0.2.0.pre" }
        expect(execute("bundle", dir: dir, env: env)).to exit_success
        expect(execute("bundle", %w(exec speaker hi), dir: dir, env: env)).
          to exit_success.and_output("Hello world, pre, #{platform_message}\n")
      end

      it "can bundle with prerelease versions with full index" do
        env = { "SPEAKER_VERSION" => "= 0.2.0.pre" }
        expect(execute("bundle", %w(--full-index), dir: dir, env: env)).to exit_success
        expect(execute("bundle", %w(exec speaker hi), dir: dir, env: env)).
          to exit_success.and_output("Hello world, pre, #{platform_message}\n")
      end
    end

    context "with default upstream gems", db_transaction: false do
      let(:bundle) { "integration_spec/default_upstream_gems" }
      it_behaves_like "a bundleable project"
    end

    # This should stay skipped until bundler sends the X-Gemfile-Source header
    context "with upstream gems via a header mirror", db_transaction: false do
      let(:bundle) { "integration_spec/header_mirror_gems" }
      it_behaves_like "a bundleable project"
    end

    context "with upstream gems", db_transaction: false do
      let(:bundle) { "integration_spec/upstream_gems" }
      it_behaves_like "a bundleable project"

      it "can successfully bundle twice" do
        expect(execute("bundle", dir: dir)).to exit_success
        expect(execute("bundle", %w(exec speaker hi), dir: dir)).
          to exit_success.and_output("Hello world, #{platform_message}\n")

        clean_bundle bundle

        expect(execute("bundle", dir: dir)).to exit_success
        expect(execute("bundle", %w(exec speaker hi), dir: dir)).
          to exit_success.and_output("Hello world, #{platform_message}\n")
      end
    end

    context "with redirecting gems" do
      let(:bundle) { "integration_spec/redirecting_gems" }
      it_behaves_like "a bundleable project"
    end

    context "with private gems", db_transaction: false do
      before do
        Gemstash::Authorization.authorize(auth_key, "all")
        Gemstash::GemPusher.new(auth, read_gem("speaker", "0.1.0")).serve
        Gemstash::GemPusher.new(auth, read_gem("speaker", "0.1.0-java")).serve
        Gemstash::GemPusher.new(auth, read_gem("speaker", "0.2.0.pre")).serve
        Gemstash::GemPusher.new(auth, read_gem("speaker", "0.2.0.pre-java")).serve
        @gemstash.env.cache.flush
      end

      let(:bundle) { "integration_spec/private_gems" }
      it_behaves_like "a bundleable project"
    end
  end
end
