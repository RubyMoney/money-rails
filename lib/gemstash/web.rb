require "sinatra/base"
require "json"
require "gemstash"

module Gemstash
  #:nodoc:
  class Web < Sinatra::Base
    def initialize(gemstash_env: nil, http_client_builder: nil)
      @gemstash_env = gemstash_env || Gemstash::Env.new
      @http_client_builder = http_client_builder || HTTPClientBuilder.new
      Gemstash::Env.current = @gemstash_env
      super()
    end

    before do
      Gemstash::Env.current = @gemstash_env
      @gem_source = env["gemstash.gem_source"].new(self)
    end

    def http_client_for(server_url)
      @http_client_builder.for(server_url)
    end

    not_found do
      status 404
      body JSON.dump("error" => "Not found", "code" => 404)
    end

    get "/" do
      @gem_source.serve_root
    end

    get "/api/v1/dependencies" do
      @gem_source.serve_dependencies
    end

    get "/api/v1/dependencies.json" do
      @gem_source.serve_dependencies_json
    end

    post "/api/v1/gems" do
      @gem_source.serve_add_gem
    end

    delete "/api/v1/gems/yank" do
      @gem_source.serve_yank
    end

    put "/api/v1/gems/unyank" do
      @gem_source.serve_unyank
    end

    post "/api/v1/add_spec.json" do
      @gem_source.serve_add_spec_json
    end

    post "/api/v1/remove_spec.json" do
      @gem_source.serve_remove_spec_json
    end

    get "/names" do
      @gem_source.serve_names
    end

    get "/versions" do
      @gem_source.serve_versions
    end

    get "/info/:name" do
      @gem_source.serve_info(params[:name])
    end

    get "/quick/Marshal.4.8/:id" do
      @gem_source.serve_marshal(params[:id])
    end

    get "/fetch/actual/gem/:id" do
      @gem_source.serve_actual_gem(params[:id])
    end

    get "/gems/:id" do
      @gem_source.serve_gem(params[:id])
    end

    get "/latest_specs.4.8.gz" do
      @gem_source.serve_latest_specs
    end

    get "/specs.4.8.gz" do
      @gem_source.serve_specs
    end

    get "/prerelease_specs.4.8.gz" do
      @gem_source.serve_prerelease_specs
    end
  end
end
