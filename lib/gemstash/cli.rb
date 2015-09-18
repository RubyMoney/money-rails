require "gemstash"
require "thor"

class Gemstash::CLI < Thor
  desc "setup", "Checks for dependencies and does initial setup"
  def setup
  end

  desc "start", "Starts your gemstash server"
  def start
  end

  desc "stop", "Stops your gemstash server"
  def stop
  end
end
