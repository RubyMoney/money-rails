require "sinatra/base"
require "json"
require "gemstash"
require "gemstash/strategy"

module Gemstash
  #:nodoc:
  class Web < Sinatra::Base
    API_REQUEST_LIMIT = 200

    def initialize(gem_strategy: nil, web_helper: nil)
      @web_helper   = web_helper || Gemstash::RubygemsWebHelper.new
      @strategy     = gem_strategy || Gemstash::RedirectionStrategy.new(web_helper: @web_helper)
      @dependencies = Gemstash::Dependencies.new(@web_helper)
      super()
    end

    not_found do
      status 404
      body JSON.dump("error" => "Not found", "code" => 404)
    end

    get "/" do
      @strategy.serve_root(self)
    end

    get "/api/v1/dependencies" do
      gems = gems_from_params

      if gems.length > API_REQUEST_LIMIT
        halt 422, "Too many gems (use --full-index instead)"
      end

      content_type "application/octet-stream"
      Marshal.dump @dependencies.fetch(gems)
    end

    get "/api/v1/dependencies.json" do
      gems = gems_from_params

      if gems.length > API_REQUEST_LIMIT
        halt 422, {
          "error" => "Too many gems (use --full-index instead)",
          "code"  => 422
        }.to_json
      end

      content_type "application/json;charset=UTF-8"
      @dependencies.fetch(gems).to_json
    end

    post "/api/v1/gems" do
      # TODO: Handle auth: request.env["HTTP_AUTHORIZATION"]
      Gemstash::GemPusher.new(request.body.read).push
      halt 403, "Not yet supported"
    end

    delete "/api/v1/gems/yank" do
      halt 403, "Not yet supported"
    end

    put "/api/v1/gems/unyank" do
      halt 403, "Not yet supported"
    end

    post "/api/v1/add_spec.json" do
      halt 403, "Not yet supported"
    end

    post "/api/v1/remove_spec.json" do
      halt 403, "Not yet supported"
    end

    get "/names" do
      halt 403, "Not yet supported"
    end

    get "/versions" do
      halt 403, "Not yet supported"
    end

    get "/info/:name" do
      halt 403, "Not yet supported"
    end

    get "/quick/Marshal.4.8/:id" do
      @strategy.serve_marshal(self, id: params[:id])
    end

    get "/fetch/actual/gem/:id" do
      @strategy.serve_actual_gem(self, id: params[:id])
    end

    get "/gems/:id" do
      @strategy.serve_gem(self, id: params[:id])
    end

    get "/latest_specs.4.8.gz" do
      @strategy.serve_latest_specs(self)
    end

    get "/specs.4.8.gz" do
      @strategy.serve_specs(self)
    end

    get "/prerelease_specs.4.8.gz" do
      @strategy.serve_prerelease_specs(self)
    end

  private

    def gems_from_params
      halt(200) if params[:gems].nil? || params[:gems].empty?
      params[:gems].split(",").uniq
    end
  end
end
