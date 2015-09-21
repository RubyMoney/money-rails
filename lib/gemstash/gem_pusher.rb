require "rubygems/package"
require "stringio"

module Gemstash
  #:nodoc:
  class GemPusher
    def initialize(content)
      @content = content
    end

    def push
    end

  private

    def spec
      gem.spec
    end

    def gem
      @gem ||= ::Gem::Package.new(StringIO.new(@content))
    end
  end
end
