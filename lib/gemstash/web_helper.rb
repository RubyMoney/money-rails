require "gemstash"
require "open-uri"

module Gemstash
  #:nodoc:
  class WebHelper
    def get(url)
      open(url, &:read)
    end
  end

  #:nodoc:
  class RubygemsWebHelper < WebHelper
    def get(path)
      super("#{Gemstash::Env.rubygems_url}#{path}")
    end
  end
end
