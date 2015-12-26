[![Build Status](https://travis-ci.org/bundler/gemstash.svg?branch=master)](https://travis-ci.org/bundler/gemstash)

<p align="center"><img src="gemstash.png" /></p>

## What is Gemstash?

Gemstash is both a cache for remote servers such as https://www.rubygems.org,
and a private gem source.

If you are using [bundler](http://bundler.io/) across many machines that have
access to a server within your control, you might want to use Gemstash.

If you produce gems that you don't want everyone in the world to have access to,
you might want to use Gemstash.

If you frequently bundle the same set of gems across multiple projects, you
might want to use Gemstash.

Are you only using gems from https://www.rubygems.org, and don't bundle the same
gems frequently? Well, maybe you don't need Gemstash... yet.

## Quickstart Guide

### Setup

Gemstash is designed to be quick and painless to get set up. By the end of this
Quickstart Guide, you will be able to bundle stashed gems from public sources
against a Gemstash server running on your machine.

Install Gemstash to get started:

```
$ gem install gemstash
```

After it is installed, starting Gemstash requires no additional steps. Simply
start the Gemstash server with the `gemstash` command:

```
$ gemstash start
```

You may have noticed that the command finished quickly. This is because Gemstash
will run the server in the background by default. The server runs on port 9292.

### Bundling

With the server running, you can bundle against it. Tell Bundler that you want
to use Gemstash to find gems from RubyGems.org:

```
$ bundle config mirror.https://rubygems.org http://localhost:9292
```

Now you can create a Gemfile and install gems through Gemstash:

```ruby
# ./Gemfile
source "https://rubygems.org"
gem "rubywarrior"
```

The gems you include should be gems you don't yet have installed,
otherwise Gemstash will have nothing to stash. Now bundle:

```
$ bundle install --path .bundle
```

Your Gemstash server has fetched the gems from https://www.rubygems.org and
cached them for you! To prove this, you can disable your Internet connection and
try again. The gem dependencies from https://www.rubygems.org are cached for 30
minutes, so if you bundle again before that, you can successfully bundle without
an Internet connection:

```
$ # Disable your Internet first!
$ rm -rf Gemfile.lock .bundle
$ bundle
```

### Stopping the Server

Once you've finish using your Gemstash server, you can stop it just as easily as
you started it:

```
$ gemstash stop
```

You'll also want to tell Bundler that it can go back to getting gems from
RubyGems.org directly, instead of going through Gemstash:

```
$ bundle config --delete mirror.https://rubygems.org
```

### Under the Hood

You might wonder where the gems are stored. After running the commands above,
you will find a new directory at `~/.gemstash`. This directory holds all the
cached and private gems. It also has a server log, the database, and
configuration for Gemstash. If you prefer, you can [point to a different
directory](docs/config.md#files).

Gemstash uses [SQLite](https://www.sqlite.org/) to store details about private
gems. The database will be located in `~/.gemstash`, however you won't see the
database appear until you start using private gems. If you prefer, you can [use
a different database](docs/config.md#database).

Gemstash temporarily caches things like gem dependencies in memory. Anything
cached in memory will last for 30 minutes before being retrieved again. You can
[use memcached](docs/config.md#cache) instead of caching in memory. Gem files
are always cached permanently, so bundling with a `Gemfile.lock` with all gems
cached will never call out to https://www.rubygems.org.

The server you ran is provided via [Puma](http://puma.io/) and
[Rack](http://rack.github.io/), however they are not customizable at this point.

## Deep Dive

For a deep dive into the following subjects, follow the links:
* [Private gems](docs/private_gems.md)
* [Multiple gem sources](docs/multiple_sources.md)
* [Using Gemstash as a mirror](docs/mirror.md)
* [Customizing the server (database, storage, caching, and more)](docs/config.md)
* [Deploying Gemstash](docs/deploy.md)
* [Debugging Gemstash](docs/debug.md)

## Reference

For an anatomy of various configuration and commands, follow the links:
* [Configuration](docs/reference.md#configuration)
* [Authorize](docs/reference.md#authorize)
* [Start](docs/reference.md#start)
* [Stop](docs/reference.md#stop)
* [Status](docs/reference.md#status)
* [Setup](docs/reference.md#setup)
* [Version](docs/reference.md#version)

To see what has changed in recent versions of Gemstash, see the
[CHANGELOG](CHANGELOG.md).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake` to run RuboCop and the tests. While developing, you can run
`bin/gemstash` to run Gemstash. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/bundler/gemstash. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](CODE_OF_CONDUCT.md) code of conduct.

## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
