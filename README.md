[![Build Status](https://travis-ci.org/bundler/gemstash.svg?branch=master)](https://travis-ci.org/bundler/gemstash)

# Gemstash

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

With the server running, you can bundle against it. Create a simple `Gemfile`
like the following:
```ruby
source "http://localhost:9292"
gem "rubywarrior"
```

The first line is important, as it will tell Bundler to use your new Gemstash
server. The gems you include should be gems you don't yet have installed,
otherwise Gemstash will have nothing to stash. Now bundle:
```
$ bundle
```

Your Gemstash server has fetched the gems from https://www.rubygems.org and
cached them for you! To prove this, you can disable your Internet connection and
try again. The gem dependencies from https://www.rubygems.org are cached for 30
minutes, so if you bundle again before that, you can successfully bundle without
an Internet connection:
```
$ # Disable your Internet first!
$ rm Gemfile.lock
$ gem uninstall rubywarrior
$ bundle
```

### Stopping the Server

Once you've finish using your Gemstash server, you can stop it just as easily as
you started it:
```
$ gemstash stop
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
cached will last for 30 minutes before being retrieved again. You can [use
memcached[(docs/config.md#cache) instead of caching in memory.

The server you ran is provided via [Puma](http://puma.io/) and
[Rack](http://rack.github.io/), however they are not customizable at this point.

## Deep Dive

For a deep dive into the following subjects, follow the links:
* [Private gems](docs/private_gems.md)
* [Multiple gem sources](docs/multiple_sources.md)
* [Using Gemstash as a mirror](docs/mirror.md)
* [Customizing the server (database, storage, caching, and more)](docs/config.md)
* [Upgrading Gemstash](docs/upgrade.md)
* [Debugging Gemstash](docs/debug.md)

## Development

After checking out the repo, run `bundle` to install dependencies. Then, run
`rake` to run RuboCop and the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/bundler/gemstash. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](CODE_OF_CONDUCT.md) code of conduct.

## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
