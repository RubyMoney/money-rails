require "spec_helper"

describe "gemstash concurrency tests" do
  TIMEOUT = 2

  def write_thread(resource_id)
    env = Gemstash::Env.current

    Thread.new do
      Thread.current[:name] = "write-thread-for-#{resource_id}"
      Gemstash::Env.current = env
      storage = Gemstash::Storage.for("concurrent_test")
      resource = storage.resource(resource_id.to_s)
      resource.save({ file: "Example content" }, example: true)
    end
  end

  def read_thread(resource_id)
    env = Gemstash::Env.current

    Thread.new do
      Thread.current[:name] = "read-thread-for-#{resource_id}"
      Gemstash::Env.current = env
      storage = Gemstash::Storage.for("concurrent_test")
      resource = storage.resource(resource_id.to_s)

      if resource.exist?(:file)
        raise "Property mismatch" unless resource.properties[:example]
        raise "Content mismatch" unless resource.content(:file) == "Example content"
      end
    end
  end

  def check_for_errors_and_deadlocks(threads)
    threads = [threads] unless threads.is_a?(Array)
    error = nil

    threads.each do |thread|
      begin
        # Join raises an error if the thread raised an error
        result = thread.join(TIMEOUT)
        raise "Thread #{thread[:name]} did not die in #{TIMEOUT} seconds, possible deadlock!" unless result
      rescue => e
        error = e unless error
      end
    end

    raise error if error
  end

  describe "storage" do
    it "works with serial code" do
      check_for_errors_and_deadlocks(write_thread(1))
      check_for_errors_and_deadlocks(read_thread(1))
      check_for_errors_and_deadlocks(read_thread(2))
      check_for_errors_and_deadlocks(write_thread(2))
    end

    it "works with concurrent reads and writes" do
      threads = []

      1.upto(25) do |i|
        10.times do
          if rand(2) == 0
            threads << write_thread(i)
            threads << read_thread(i)
          else
            threads << read_thread(i)
            threads << write_thread(i)
          end
        end
      end

      check_for_errors_and_deadlocks(threads)
    end
  end
end
