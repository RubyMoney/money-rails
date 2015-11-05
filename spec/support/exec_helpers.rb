require "bundler/version"
require "open3"

# Helpers for executing commands and asserting the results.
module ExecHelpers
  def execute(command, dir: nil, env: {})
    Result.new(env, command, dir)
  end

  # Executes and stores the results for an external command.
  class Result
    attr_reader :command, :dir, :output

    def initialize(env, command, dir)
      @command = command
      @env = env
      @original_dir = dir
      @dir = dir || File.expand_path(".")
      @output, @status = Open3.capture2e(patched_env, @command, chdir: @dir)
      fix_jruby_output
    end

    def successful?
      @status.success?
    end

    def matches_output?(expected)
      return true unless expected
      @output == expected
    end

  private

    def fix_jruby_output
      return unless RUBY_PLATFORM == "java"
      # Travis builds or runs JRuby in a way that outputs the following warning for some reason
      @output.gsub!(/^.*warning: unknown property jruby.cext.enabled\n/, "")

      if Gem::Requirement.new(">= 1.11.0").satisfied_by?(Gem::Version.new(Bundler::VERSION))
        raise "Please remove ExecHelpers#fix_jruby_output if the warning doesn't occur anymore"
      end

      @output.gsub!(/^.*warning: unsupported exec option: close_others\n/, "")
    end

    def patched_env
      @patched_env ||= faster_jruby_env.merge(clear_bundler_env).merge(clear_ruby_env).merge(@env)
    end

    def clear_ruby_env
      {
        "RUBYLIB" => nil,
        "RUBYOPT" => nil,
        "GEM_PATH" => ENV["_ORIGINAL_GEM_PATH"]
      }
    end

    def clear_bundler_env
      if @original_dir
        gemfile_path = File.join(@original_dir, "Gemfile")
        bundle_gemfile = gemfile_path if File.exist?(gemfile_path)
      end

      { "BUNDLE_GEMFILE" => bundle_gemfile }
    end

    def faster_jruby_env
      return {} unless RUBY_PLATFORM == "java"
      jruby_opts = "--dev"

      if command.start_with?("bundle")
        bundler_patch = File.expand_path("../jruby_bundler_monkeypatch.rb", __FILE__)
        raise "Spaces in your path will cause build failures!" if bundler_patch.include?(" ")
        jruby_opts += " -r#{bundler_patch}"
      end

      { "JRUBY_OPTS" => jruby_opts }
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
