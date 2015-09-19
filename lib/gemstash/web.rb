require "sinatra/base"
require "json"
require "gemstash"

module Gemstash
  #:nodoc:
  class Web < Sinatra::Base
    API_REQUEST_LIMIT = 200

    def initialize
      @web_helper = Gemstash::RubygemsWebHelper.new
      @dependencies = Gemstash::Dependencies.new(@web_helper)
      super()
    end

    not_found do
      status 404
      body JSON.dump("error" => "Not found", "code" => 404)
    end

    get "/" do
      cache_control :public, :max_age => 31_536_000
      redirect @web_helper.url
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
      redirect @web_helper.url("/quick/Marshal.4.8/#{params[:id]}")
    end

    get "/fetch/actual/gem/:id" do
      redirect @web_helper.url("/fetch/actual/gem/#{params[:id]}")
    end

    get "/gems/:id" do
      redirect @web_helper.url("/gems/#{params[:id]}")
    end

    get "/latest_specs.4.8.gz" do
      redirect @web_helper.url("/latest_specs.4.8.gz")
    end

    get "/specs.4.8.gz" do
      redirect @web_helper.url("/specs.4.8.gz")
    end

    get "/prerelease_specs.4.8.gz" do
      redirect @web_helper.url("/prerelease_specs.4.8.gz")
    end

  private

    def gems_from_params
      halt(200) if params[:gems].nil? || params[:gems].empty?
      params[:gems].split(",").uniq
    end
  end
end
