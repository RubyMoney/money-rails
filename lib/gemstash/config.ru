require "gemstash/web"
use Rack::Deflater
run Gemstash::Web.new
