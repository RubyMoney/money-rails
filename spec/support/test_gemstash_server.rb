require "gemstash"
require "puma/cli"
require "support/server_check"

# Launches a test Gemstash server directly via Puma.
class TestGemstashServer
  def initialize(port:, config:)
    @port = port
    args = %w(--config -)
    args += %w(--workers 0)
    args += %w(--threads 0:4)
    args += %w(--environment test)
    args += ["--port", port.to_s]
    args << File.expand_path("../test_gemstash_server.ru", __FILE__)
    config = Gemstash::Configuration.new(config: config)
    cache = Gemstash::Env.current.cache
    env = Gemstash::Env.new(config, cache: cache)
    # rubocop:disable Style/GlobalVars
    $test_gemstash_server_env = env
    # rubocop:enable Style/GlobalVars
    @puma_cli = Puma::CLI.new(args)
    TestGemstashServer.servers << self
  end

  def url
    "http://127.0.0.1:#{@port}"
  end

  def start
    raise "Already started!" if @started
    @started = true

    @thread = Thread.new do
      @puma_cli.run
    end

    ServerCheck.new(@port).wait
  end

  def stop
    return if @stopped
    @stopped = true
    @puma_cli.halt
  end

  def join
    raise "Only join if stopping!" unless @stopped
    return if @thread.join(10)
    puts "WARNING: TestGemstashServer is not stopping!"
  end

  def self.join_all
    servers.each(&:join)
  end

  def self.servers
    @servers ||= []
  end
end
