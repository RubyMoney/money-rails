require "open3"

#:nodoc:
module ExecHelpers
  def execute(command, dir:)
    Result.new(*Open3.capture2e(command, chdir: dir))
  end

  #:nodoc:
  class Result
    attr_reader :output

    def initialize(output, status)
      @output = output
      @status = status
    end

    def successful?
      @status.success?
    end
  end
end
