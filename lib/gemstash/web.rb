require "sinatra/base"
require "json"
require "gemstash"
require "gemstash/env"

module Gemstash
  #:nodoc:
  class Web < Sinatra::Base
    RUBYGEMS_URL = Gemstash::Env.rubygems_url

    not_found do
      status 404
      body JSON.dump("error" => "Not found", "code" => 404)
    end

    get "/" do
      cache_control :public, :max_age => 31_536_000
      redirect RUBYGEMS_URL
    end

    get "/api/v1/dependencies" do
      redirect "#{RUBYGEMS_URL}/api/v1/dependencies?gems=#{params[:gems]}"
    end

    get "/api/v1/dependencies.json" do
      redirect "#{RUBYGEMS_URL}/api/v1/dependencies.json?gems=#{params[:gems]}"
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
      redirect "#{RUBYGEMS_URL}/quick/Marshal.4.8/#{params[:id]}"
    end

    get "/fetch/actual/gem/:id" do
      redirect "#{RUBYGEMS_URL}/fetch/actual/gem/#{params[:id]}"
    end

    get "/gems/:id" do
      redirect "#{RUBYGEMS_URL}/gems/#{params[:id]}"
    end

    get "/latest_specs.4.8.gz" do
      redirect "#{RUBYGEMS_URL}/latest_specs.4.8.gz"
    end

    get "/specs.4.8.gz" do
      redirect "#{RUBYGEMS_URL}/specs.4.8.gz"
    end

    get "/prerelease_specs.4.8.gz" do
      redirect "#{RUBYGEMS_URL}/prerelease_specs.4.8.gz"
    end
  end
end
