require "webrick"
require "support/file_helpers"
require "support/server_check"

# A wrapper for a WEBrick server for a quick web server to test against.
class SimpleServer
  include FileHelpers
  attr_reader :routes

  def initialize(hostname)
    @port = SimpleServer.next_port
    @server = WEBrick::HTTPServer.new(:Port => @port)
    @server.mount("/", Servlet, self)
    @hostname = hostname
    @routes = {}
    SimpleServer.servers << self
  end

  def url
    "http://#{@hostname}:#{@port}"
  end

  def start
    raise "Already started!" if @started
    @started = true

    @thread = Thread.new do
      @server.start
    end

    ServerCheck.new(@port).wait
  end

  def stop
    return if @stopped
    @stopped = true
    @server.stop
  end

  def stopped?
    @stopped
  end

  def join
    raise "Only join if stopping!" unless @stopped
    puts "WARNING: SimpleServer is not stopping!" unless @thread.join(10)
  end

  def self.next_port
    @next_port ||= 10_000
    @next_port += 1
  end

  def self.join_all
    servers.each(&:join)
  end

  def self.servers
    @servers ||= []
  end

  def mount(path, &block)
    @routes[path] = block
  end

  def mount_redirect(path, to)
    mount(path) do |_, response|
      response.set_redirect(WEBrick::HTTPStatus::Found, to)
    end
  end

  def mount_message(path, message, status = 200)
    mount(path) do |_, response|
      response.status = status
      response.content_type = "text/plain"
      response.body = message
    end
  end

  def mount_gem(name, version)
    mount("/gems/#{name}-#{version}.gem") do |_, response|
      response.status = 200
      response.content_type = "application/octet-stream"
      response.body = File.read(gem_path(name, version))
    end
  end

  def mount_gem_deps(name, deps)
    unless @gem_deps
      @gem_deps = {}

      mount("/api/v1/dependencies") do |request, response|
        gems = request.query["gems"]
        response.status = 200

        if gems && !gems.empty?
          response.content_type = "application/octet-stream"
          results = []

          gems.split(",").each do |gem|
            results += @gem_deps[gem] if @gem_deps.include?(gem)
          end

          response.body = Marshal.dump(results)
        end
      end
    end

    raise "Gem dependencies for '#{name}' already mounted!" if @gem_deps.include?(name)
    @gem_deps[name] = deps
  end

  #:nodoc:
  class Servlet < WEBrick::HTTPServlet::AbstractServlet
    def initialize(_, server)
      @simple_server = server
      super
    end

    # rubocop:disable Style/MethodName
    def do_GET(request, response)
      # rubocop:enable Style/MethodName
      @simple_server.routes[request.path].call request, response
    end
  end
end
