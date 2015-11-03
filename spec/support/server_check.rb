# Helper class to see when a test server is ready to receive requests.
class ServerCheck
  MAX_WAIT = 10

  def initialize(port)
    @port = port
  end

  def wait
    waited = 0

    until server_online?
      raise "Waiting too long for server to come up!" if waited >= MAX_WAIT
      sleep(0.1)
      waited += 0.1
    end
  end

  def server_online?
    Socket.tcp("127.0.0.1", @port, nil, nil, connect_timeout: 1).close
    true
  rescue Errno::EBADF
    false
  rescue Errno::ECONNREFUSED
    false
  rescue Errno::ETIMEDOUT
    true
  end
end
