require "gemstash"
use Rack::Deflater
run Gemstash::Web.new
