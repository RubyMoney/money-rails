require "gemstash"

logger = Gemstash::Logging.wrapped_logger

use Rack::Deflater
use Gemstash::MyLoggerMiddleware, logger

run Gemstash::Web.new
