# frozen_string_literal: true

# Run a JRuby program in process.
class InProcessExec
  attr_reader :status, :output

  def initialize(env, dir, args)
    raise "InProcessExec is only valid on JRuby!" unless RUBY_PLATFORM == "java"

    @env = env
    @dir = dir
    @args = args.dup
    @args[0] = @args[0][0] if @args[0].is_a?(Array)
    exec
  end

private

  def exec
    prepare_streams
    prepare_config
    @status = org.jruby.Main.new(@config).run(@args.to_java(:String)).status
    @output = @output_stream.to_string
  end

  def prepare_streams
    @input_stream = java.io.ByteArrayInputStream.new([].to_java(:byte))
    @output_stream = java.io.ByteArrayOutputStream.new
    @output_print_stream = java.io.PrintStream.new(@output_stream)
  end

  def prepare_config
    @config = org.jruby.RubyInstanceConfig.new(JRuby.runtime.instance_config)
    @config.environment = @env
    @config.current_directory = @dir
    @config.input = @input_stream
    @config.output = @output_print_stream
    @config.error = @output_print_stream
  end
end
