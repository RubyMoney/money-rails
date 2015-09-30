require "gemstash"
require "puma/commonlogger"

use Rack::Deflater
use Gemstash::Logging::RackMiddleware

if Gemstash::Env.daemonized?
  use Puma::CommonLogger, Gemstash::Logging::StreamLogger.for_stdout
end

run Gemstash::Web.new
