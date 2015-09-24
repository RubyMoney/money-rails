require "speaker/version"

#:nodoc:
module Speaker
  def self.usage
    $stderr.puts "Usage: speaker [hi|bye]"
    exit(1)
  end

  def self.say(argv)
    if argv.size != 1
      usage
    end

    if argv.first == "hi"
      puts "Hello world"
    elsif argv.first == "bye"
      puts "Goodbye moon"
    else
      usage
    end
  end
end
