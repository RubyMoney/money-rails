require "gemstash"
require "set"

module Gemstash
  #:nodoc:
  class GemFetcher
    def initialize(http_client)
      @http_client = http_client
      @valid_headers = Set.new(["etag", "content-type", "content-length", "last-modified"])
    end

    def fetch(gem_id, &block)
      @http_client.get("/gems/#{gem_id}") do |body, headers|
        properties = filter_headers(headers)
        validate_download(body, properties)
        yield body, properties
      end
    end

  private

    def filter_headers(headers)
      headers.inject({}) do|properties, (key, value)|
        properties[key.downcase] = value if @valid_headers.include?(key.downcase)
        properties
      end
    end

    def validate_download(content, headers)
      expected_size = content_length(headers)
      raise "Incomplete download, only #{body.length} was downloaded out of #{expected_size}" \
        if content.length < expected_size
    end

    def content_length(headers)
      headers["content-length"].to_i
    end
  end
end
