require "open3"

# Helpers for executing commands and asserting the results.
module ExecHelpers
  def execute(command, dir:)
    env = {
      "BUNDLE_GEMFILE" => nil,
      "RUBYLIB" => nil,
      "RUBYOPT" => nil,
      "GEM_PATH" => ENV["_ORIGINAL_GEM_PATH"]
    }
    Result.new(env, command, dir)
  end

  # Executes and stores the results for an external command.
  class Result
    attr_reader :command, :dir, :output

    def initialize(env, command, dir)
      @command = command
      @dir = dir
      @output, @status = Open3.capture2e(env, command, chdir: dir)
    end

    def successful?
      @status.success?
    end

    def matches_output?(expected)
      return true unless expected
      @output == expected
    end
  end
end

RSpec::Matchers.define :exit_success do
  match do |actual|
    actual.successful? && actual.matches_output?(@expected_output)
  end

  chain(:and_output) do |message|
    @expected_output = message
  end

  failure_message do |actual|
    if actual.successful?
      "expected '#{actual.command}' in '#{actual.dir}' to output:
#{@expected_output}

but instead it output:
#{actual.output}"
    else
      "expected '#{actual.command}' in '#{actual.dir}' to exit with a success code, but it didn't.
the command output was:
#{actual.output}"
    end
  end
end
