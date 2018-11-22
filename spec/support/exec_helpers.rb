# frozen_string_literal: true

require "bundler/version"
require "open3"
require "pathname"

# Helpers for executing commands and asserting the results.
module ExecHelpers
  def execute(command, args = [], dir: nil, env: {})
    if RUBY_PLATFORM == "java"
      JRubyResult.new(env, command, args, dir)
    else
      Result.new(env, command, args, dir)
    end
  end

  # Executes and stores the results for an external command.
  class Result
    attr_reader :command, :args, :dir, :output

    def initialize(env, command, args, dir)
      @command = command
      @args = args
      @env = env
      @original_dir = dir
      @dir = dir || File.expand_path("../../..", __FILE__)
      exec
      fix_jruby_output
    end

    def exec
      @output, @status = Open3.capture2e(patched_env, command, *args, chdir: dir)
    end

    def successful?
      @status.success?
    end

    def display_command
      display_args = args.map do |x|
        if x =~ /\s/
          "'#{x}'"
        else
          x
        end
      end

      ([command] + display_args).join(" ")
    end

    def matches_output?(expected)
      return true unless expected

      if expected.is_a?(Regexp)
        @output =~ expected
      else
        @output == expected
      end
    end

  private

    def fix_jruby_output
      return unless RUBY_PLATFORM == "java"
      # Travis builds or runs JRuby in a way that outputs the following warning for some reason
      @output.gsub!(/^.*warning: unknown property jruby.cext.enabled\n/, "")
    end

    def patched_env
      @patched_env ||= clear_bundler_env.merge(clear_ruby_env).merge(@env)
    end

    def clear_ruby_env
      {
        "RUBYLIB" => nil,
        "RUBYOPT" => nil,
        "GEM_PATH" => original_gem_path
      }
    end

    def original_gem_path
      if !(ENV["_ORIGINAL_GEM_PATH"] || "").strip.empty?
        ENV["_ORIGINAL_GEM_PATH"]
      elsif !(ENV["BUNDLE_ORIG_GEM_PATH"] || "").strip.empty?
        ENV["BUNDLE_ORIG_GEM_PATH"]
      elsif !(ENV["BUNDLER_ORIG_GEM_PATH"] || "").strip.empty?
        ENV["BUNDLER_ORIG_GEM_PATH"]
      else
        raise "Could not determine the original GEM_PATH!"
      end
    end

    def clear_bundler_env
      if @original_dir
        gemfile_path = File.join(@original_dir, "Gemfile")
        bundle_gemfile = gemfile_path if File.exist?(gemfile_path)
      end

      { "BUNDLE_GEMFILE" => bundle_gemfile }
    end
  end

  # Executes and stores the results for an external command, but does it in
  # process with a separate JRuby instance rather than a process.
  class JRubyResult < Result
    def exec
      binstub_dir = File.expand_path("../jruby_binstubs", __FILE__)
      binstub = File.join(binstub_dir, File.basename(command))
      raise "Missing binstub for #{command}" unless File.exist?(binstub)
      exec_in_process(binstub)
    end

    def successful?
      @process.status == 0
    end

  private

    def exec_in_process(binstub)
      @process = InProcessExec.new(patched_env, dir, [binstub] + args)
      @output = @process.output
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
      "expected '#{actual.display_command}' in '#{actual.dir}' to output:
#{@expected_output}

but instead it output:
#{actual.output}"
    else
      "expected '#{actual.display_command}' in '#{actual.dir}' to exit with a success code, but it didn't.
the command output was:
#{actual.output}"
    end
  end
end
