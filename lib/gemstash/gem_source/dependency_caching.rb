# frozen_string_literal: true

module Gemstash
  module GemSource
    # Module for caching dependencies in a GemSource.
    module DependencyCaching
      API_REQUEST_LIMIT = 200

      def serve_dependencies
        gems = gems_from_params

        halt 422, "Too many gems (use --full-index instead)" if gems.length > API_REQUEST_LIMIT

        content_type "application/octet-stream"
        Marshal.dump dependencies.fetch(gems)
      end

      def serve_dependencies_json
        gems = gems_from_params

        if gems.length > API_REQUEST_LIMIT
          halt 422, {
            "error" => "Too many gems (use --full-index instead)",
            "code" => 422
          }.to_json
        end

        content_type "application/json;charset=UTF-8"
        dependencies.fetch(gems).to_json
      end

    private

      def gems_from_params
        halt(200) if params[:gems].nil? || params[:gems].empty?
        params[:gems].split(",").uniq
      end
    end
  end
end
