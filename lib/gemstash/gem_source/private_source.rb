require "gemstash"

module Gemstash
  module GemSource
    # GemSource for privately stored gems.
    class PrivateSource < Gemstash::GemSource::Base
      def self.matches?(env)
        chomp_path(env, "/private")
      end
    end
  end
end
