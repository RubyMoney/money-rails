require "rubygems/package"
require "stringio"

module Gemstash
  class Gem
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
