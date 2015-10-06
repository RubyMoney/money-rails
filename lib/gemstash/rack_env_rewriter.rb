require "gemstash"
require "forwardable"

module Gemstash
  # Detects patterns in the Rack env variables related to URI and rewrites
  # them, extracting parameters.
  class RackEnvRewriter
    attr_reader :regexp

    def initialize(regexp)
      @regexp = regexp
    end

    def for(rack_env)
      Context.new(self, rack_env)
    end

    # Context containing the logic and the actual Rack environment.
    class Context
      include Gemstash::Logging
      extend Forwardable
      def_delegators :@rewriter, :regexp

      def initialize(rewriter, rack_env)
        @rewriter = rewriter
        @rack_env = rack_env
      end

      def matches?
        matches_request_uri? && matches_path_info?
      end

      def rewrite
        check_match
        log_start = "Rewriting '#{@rack_env["REQUEST_URI"]}'"
        @rack_env["REQUEST_URI"][@request_uri_match.begin(0)...@request_uri_match.end(0)] = ""
        @rack_env["PATH_INFO"][@path_info_match.begin(0)...@path_info_match.end(0)] = ""
        log.info "#{log_start} to '#{@rack_env["REQUEST_URI"]}'"
      end

      def captures
        @params ||= begin
          check_match
          @path_info_match.names.inject({}) do |result, name|
            result[name] = @path_info_match[name]
            result
          end
        end
      end

    private

      def matches_request_uri?
        @request_uri_match ||= @rack_env["REQUEST_URI"].match(regexp)
      end

      def matches_path_info?
        @path_info_match ||= @rack_env["PATH_INFO"].match(regexp)
      end

      def check_match
        raise "Rack env did not match!" unless @request_uri_match && @path_info_match
      end
    end
  end
end
