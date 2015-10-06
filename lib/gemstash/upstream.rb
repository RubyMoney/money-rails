module Gemstash
  #:nodoc:
  class Upstream
    extend Forwardable
    include Gemstash::Env::Helper

    def_delegators :@uri, :scheme, :host, :user, :password, :to_s

    def initialize(upstream)
      @uri = URI(URI.decode(upstream))
      raise "URL '#{@uri}' is not valid!" unless @uri.to_s =~ URI.regexp
    end

    def url(path = nil, params = nil)
      params = "?#{params}" if !params.nil? && !params.empty?
      "#{self}#{path}#{params}"
    end
  end
end
