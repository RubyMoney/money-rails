require "bundler"
require "bundler/fetcher"

module Bundler
  #:nodoc:
  class Fetcher
    # The Bundler user_agent uses SecureRandom, which causes the specs
    # to run out of entropy and run a lot longer than they need to.
    def user_agent
      "gemstash spec"
    end
  end
end
