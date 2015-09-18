require "gemstash"
require "dalli"

class Gemstash::Env
  def self.memcached_client
    @memcached_client ||= Dalli::Client.new
  end
end
