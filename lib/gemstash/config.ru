require "gemstash"

use Rack::Deflater
use Rack::CommonLogger, Gemstash::Logging.raw_logger

run Gemstash::Web.new
