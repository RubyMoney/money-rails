require "gemstash"

use Rack::Deflater
use Gemstash::MyLoggerMiddleware, Gemstash::Logging.wrapped_logger

run Gemstash::Web.new
