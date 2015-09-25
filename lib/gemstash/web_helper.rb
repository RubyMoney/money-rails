require "gemstash"
require "open-uri"

module Gemstash
  #:nodoc:
  class WebError < StandardError
    attr_reader :code

    def initialize(message, code)
      @code = code
      super(message)
    end
  end

  #:nodoc:
  class WebHelper
    def initialize(rubygems_url = nil)
      @rubygems_url = rubygems_url || Gemstash::Env.config[:rubygems_url]
    end

    def get(path)
      open(url(path), &:read)
    rescue OpenURI::HTTPError => e
      raise WebError.new(e.io.read, e.io.status.first.to_i)
    end

    def url(path = nil)
      "#{@rubygems_url}#{path}"
    end
  end
end
