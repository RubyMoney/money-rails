module Gemstash
  # An action was not authorized and should cause the server to send a 401.
  class NotAuthorizedError < StandardError
  end
end
