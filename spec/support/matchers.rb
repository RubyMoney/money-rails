RSpec::Matchers.define :redirect_to do |expected|
  match do |actual|
    actual.redirect? && actual.headers["Location"] == expected
  end

  match_when_negated do |actual|
    actual.redirect? && actual.headers["Location"] != expected
  end

  failure_message do |actual|
    if actual.redirect?
      "expected response to redirect to '#{expected}', but instead it \
redirected to '#{actual.headers["Location"]}'"
    else
      "expected response to be a redirect, but it wasn't"
    end
  end

  failure_message_when_negated do |actual|
    if actual.redirect?
      "expected response to not redirect to '#{expected}', but it did"
    else
      "expected response to be a redirect, but it wasn't"
    end
  end
end
