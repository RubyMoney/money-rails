# Multiple Gem Sources

Gemstash will stash from any amount of gem sources. By the end of this guide,
you will be able to bundle using multiple gem sources, all stashed within your
Gemstash server.

## Default Source

When you don't provide an explicit source (as with the [Quickstart
Guide](../README.md#quickstart-guide)), your gems will be fetched from
https://www.rubygems.org. This default source is not set in stone. To change it,
you need only edit the Gemstash configuration found at `~/.gemstash/config.yml`:
```yaml
# ~/.gemstash/config.yml
---
:rubygems_url: https://my.gem-source.local
```

Make sure to restart your Gemstash server after changing the config:
```
$ gemstash stop
$ gemstash start
```

Once restarted, bundling against `http://localhost:9292` will fetch gems from
`https://my.gem-source.local`. If you had bundled before making these changes,
fear not; bundling with a different default gem source will store gems in a
separate location, ensuring different sources won't leak between eachother.

## Bundling with Multiple Sources

Changing the default source won't help you if you need to bundle against
https://www.rubygems.org along with additional sources. If you need to bundle
with multiple gem sources, Gemstash doesn't need to be specially configured.
Your Gemstash server will honor any gem source specified via a specialized URL.
Consider the following `Gemfile`:
```ruby
# ./Gemfile
require "cgi"
source "http://localhost:9292"
gem "rubywarrior"

source "http://localhost:9292/upstream/#{CGI.escape("https://my.gem-source.local")}" do
  gem "my-gem"
end
```

Notice the `CGI.escape` call in the second source. This is important, as it
properly URL escapes the source URL so Gemstash knows what gem source you want.
The `/upstream` prefix tells Gemstash to use a gem source other than the default
source. You can now bundle with the additional source.

## Redirecting

Gemstash supports an alternate mode of specifying your gem sources. If you want
Gemstash to redirect Bundler to your given gem sources, then you can specify
your `Gemfile` like so:
```ruby
# ./Gemfile
require "cgi"
source "http://localhost:9292/redirect/#{CGI.escape("https://www.rubygems.org")}"
gem "rubywarrior"
```

Notice the `/redirect` prefix. This prefix tells Gemstash to redirect API calls
to the provided URL. Redirected calls like this will not be cached by Gemstash,
and gem files will not be stashed, even if they were previously cached or
stashed from the same gem source.
