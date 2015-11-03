require "speaker/version"
require "speaker/platform"

#:nodoc:
module Speaker
  def self.usage
    $stderr.puts "Usage: speaker [hi|bye]"
    exit(1)
  end

  def self.say(argv)
    usage if argv.size != 1

    if argv.first == "hi"
      puts "Hello world, #{Speaker::Platform.name}"
    elsif argv.first == "bye"
      puts "Goodbye moon, #{Speaker::Platform.name}"
    else
      usage
    end
  end
end
