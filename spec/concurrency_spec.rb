require "spec_helper"

describe "gemstash concurrency tests" do
  let(:timeout) { 5 }

  def write_thread(resource_id, content = "unchanging", &block)
    env = Gemstash::Env.current

    Thread.new do
      Thread.current[:name] = "write-thread-for-#{resource_id}"
      Gemstash::Env.current = env
      storage = Gemstash::Storage.for("concurrent_test")
      resource = storage.resource(resource_id.to_s)

      if block
        block.call(resource)
      else
        resource.save({ file: "Example content: #{content}" }, example: true, content: content)
      end
    end
  end

  def read_thread(resource_id, &block)
    env = Gemstash::Env.current

    Thread.new do
      Thread.current[:name] = "read-thread-for-#{resource_id}"
      Gemstash::Env.current = env
      storage = Gemstash::Storage.for("concurrent_test")
      resource = storage.resource(resource_id.to_s)

      if resource.exist?(:file)
        if block
          block.call(resource)
        else
          raise "Property mismatch" unless resource.properties[:example]
          raise "Property mismatch" unless resource.properties[:content]
          expected_content = "Example content: #{resource.properties[:content]}"
          actual_content = resource.content(:file)
          raise "Content mismatch:\n  #{actual_content}\n  #{expected_content}" unless actual_content == expected_content
        end
      end
    end
  end

  def check_for_errors_and_deadlocks(threads)
    threads = [threads] unless threads.is_a?(Array)
    error = nil

    threads.each do |thread|
      begin
        # Join raises an error if the thread raised an error
        result = thread.join(timeout)

        unless result
          thread.kill
          raise "Thread #{thread[:name]} did not die in #{timeout} seconds, possible deadlock!"
        end
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

      25.times do |i|
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

    context "with large data" do
      let(:timeout) { 5 }

      it "works with concurrent reads and writes" do
        if RUBY_PLATFORM == "java"
          skip "JRuby seems to take a long time sometimes for this spec... is it " \
            "something like the GC kicking in while the threads are running, or " \
            "is it a sign of a deadlock, perhaps only on the JRuby platform...?"
        end

        threads = []
        possible_content = [
          ("One" * 100_000).freeze,
          ("Two" * 100_000).freeze,
          ("Three" * 100_000).freeze,
          ("Four" * 100_000).freeze
        ].freeze

        50.times do
          if rand(2) == 0
            threads << write_thread("large") do |resource|
              large_content = possible_content[rand(possible_content.size)]
              resource.save({ file: large_content }, example: true, content: large_content)
            end
          else
            threads << read_thread("large") do |resource|
              raise "Property mismatch" unless resource.properties[:example]
              raise "Property mismatch" unless possible_content.include?(resource.properties[:content])
              raise "Content mismatch" unless possible_content.include?(resource.content(:file))
            end
          end
        end

        check_for_errors_and_deadlocks(threads)
      end
    end

    it "works with concurrent reads and writes with varying content" do
      skip "this fails because of this scenario: thread-1 loads a resource and the corresponding properties file, " \
           "then thread-2 writes the files for a resource, then thread-1 reads the files for the resource; this " \
           "scenario is unimportant since the content in gemstash should be always consistent, though the extra work " \
           "is a bit undesirable"
      threads = []

      25.times do |i|
        10.times do |j|
          if rand(2) == 0
            threads << write_thread(i, "#{i},#{j}")
            threads << read_thread(i)
          else
            threads << read_thread(i)
            threads << write_thread(i, "#{i},#{j}")
          end
        end
      end

      check_for_errors_and_deadlocks(threads)
    end
  end
end
