require "digest"

module Gemstash
  #:nodoc:
  class Upstream
    extend Forwardable
    include Gemstash::Env::Helper

    def_delegators :@uri, :scheme, :host, :user, :password, :to_s

    def initialize(upstream)
      @uri = URI(URI.decode(upstream.to_s))
      raise "URL '#{@uri}' is not valid!" unless @uri.to_s =~ URI.regexp
    end

    def url(path = nil, params = nil)
      params = "?#{params}" if !params.nil? && !params.empty?
        "#{self}#{path}#{params}"
    end

    def auth?
      ! user.to_s.empty? && ! password.to_s.empty?
    end
  end

  #:nodoc:
  class UpstreamGemName
    def initialize(upstream, name)
      @upstream = upstream
      @name = name.gsub(%r{\.gem$}i, "")
    end

    def to_s
      return "#{@name}_#{hashed_auth}" if @upstream.auth?
      @name
    end

  private

    # Quite naive for now, but it is really easy to change this and add some
    # salt later
    def hashed_auth
      Digest::MD5.hexdigest("#{@upstream.user}#{@upstream.password}")
    end
  end
end
