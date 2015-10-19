# Upgrading Gemstash

Bundler is here for the rescue to keep Gemstash up to date! Create a `Gemfile`
pointing to Gemstash:
```ruby
# ./Gemfile
source "https://www.rubygems.org"
gem "gemstash"
```

Then `bundle` to create your `Gemfile.lock`. When you are ready to upgrade,
simply `bundle update`. You may need to run `gemstash` via `bundle exec`.
Alternatively, you can `gem uninstall gemstash` and `gem install gemstash` when
you want to upgrade.

Gemstash will automatically run any necessary migrations, so updating the gem is
all that needs to be done.

It is probably wise to stop Gemstash before upgrading, then starting again once
you are done:
```
$ bundle exec gemstash stop
$ bundle update
$ bundle exec gemstash start
```

## Downgrading

It is not recommended to go backwards in Gemstash versions. Migrations may have
run that could leave the database in a bad state.
