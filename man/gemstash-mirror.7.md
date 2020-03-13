---
title: gemstash-mirror
date: October 25, 2015
section: 7
...

# Using Gemstash as a Mirror

If you don't have control over your `Gemfile`, or you don't want to force
everyone on your team to go through the Gemstash server, you can use Bundler
mirroring to bundle against your Gemstash server.

For each source in your `Gemfile`, add a mirror pointing to your Gemstash
server:
```
$ bundle config mirror.http://rubygems.org http://localhost:9292
$ bundle config mirror.https://my.gem-source.local http://localhost:9292/upstream/$(ruby -rcgi -e 'puts CGI.escape("https://my.gem-source.local")')
```

From now on, bundler will fetch gems from those sources via your Gemstash
server.

# Simpler Gemstash Mirrors

**This feature requires Bundler to be at least version `1.11.0`.**

If you are using Bundler version `1.11.0` or greater, the mirroring becomes a
bit easier:
```
$ bundle config mirror.http://rubygems.org http://localhost:9292
$ bundle config mirror.https://my.gem-source.local http://localhost:9292
```

Bundler will then send headers to Gemstash to indicate the correct upstream.
