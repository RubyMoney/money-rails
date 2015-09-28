require "webrick"
require "support/server_check"

# A wrapper for a WEBrick server for a quick web server to test against.
class SimpleServer
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
