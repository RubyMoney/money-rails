require "set"

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

RSpec::Matchers.define :match_dependencies do |expected|
  match do |actual|
    @missing = []
    actual = actual.dup

    expected.each do |expected_dep|
      index = actual.find_index do |actual_dep|
        next if expected_dep[:name] != actual_dep[:name]
        next if expected_dep[:number] != actual_dep[:number]
        next if expected_dep[:platform] != actual_dep[:platform]
        exp_dep = Set.new(expected_dep[:dependencies])
        act_dep = Set.new(actual_dep[:dependencies])
        exp_dep == act_dep
      end

      if index
        actual.delete_at(index)
      else
        @missing << expected_dep
      end
    end

    @extra = actual
    @missing.empty? && @extra.empty?
  end

  failure_message do |actual|
    "\
expected collection contained: #{expected.inspect}
actual collection contained:   #{actual.inspect}
the missing elements were:     #{@missing.inspect}
the extra elements were:       #{@actual.inspect}"
  end
end
