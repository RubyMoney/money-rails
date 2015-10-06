require "digest"

module Gemstash
  #:nodoc:
  class Upstream
    extend Forwardable

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
      !user.to_s.empty? && !password.to_s.empty?
    end

    # Utilized as the parent directory for cached gems
    def host_id
      @host_id ||= "#{host}_#{hash}"
    end

  private

    def hash
      Digest::MD5.hexdigest(to_s)
    end
  end

  #:nodoc:
  class UpstreamGemName
    def initialize(upstream, gem_name)
      @upstream = upstream
      @id = gem_name
    end

    def to_s
      name
    end

    def id
      @id
    end

    def name
      @name ||= @id.gsub(/\.gem$/i, "")
    end
  end
end
