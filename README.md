[![Build Status](https://travis-ci.org/bundler/gemstash.svg?branch=master)](https://travis-ci.org/bundler/gemstash)

# Gemstash

A gem server that lets you cache gems from rubygems.org and store private gems.

## Installation

Install the gem:

    $ gem install gemstash

That's it! If you are happy with the default config, you are ready to go!

## Usage

You may configure gemstash to use something other than the default setup. By
default, there is no required setup, but some configuration options may require
additional gems or software to be installed and available.

    $ gemstash setup
    Where should files go? [~/.gemstash]
    Cache with what? [MEMORY, memcached]
    What database adapter? [SQLITE3, postgres]
    What strategy? [CACHING, redirection]
    Checking that cache is available
    Checking that database is available
    Creating the gem storage cache folder
    You are all setup!

Starting your gemstash server is easy:

    $ gemstash start

As is stopping it:

    $ gemstash stop

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/bundler/gemstash. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](CODE_OF_CONDUCT.md) code of conduct.

## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
