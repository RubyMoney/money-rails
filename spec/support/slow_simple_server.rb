# frozen_string_literal: true

class SlowSimpleServer < SimpleServer
  def initialize(hostname, port: nil)
    @port = port || SimpleServer.next_port
    @server = WEBrick::HTTPServer.new(:Port => @port)
    @server.mount("/", SlowServlet, self)
    @hostname = hostname
    @routes = {}
    SimpleServer.servers << self
  end

  #:nodoc:
  class SlowServlet < WEBrick::HTTPServlet::AbstractServlet
    def initialize(_, server)
      @simple_server = server
      super
    end

    def do_GET(request, response) # rubocop:disable Style/MethodName
      sleep(0.3)
      @simple_server.routes[request.path].call request, response
    end
  end
end
