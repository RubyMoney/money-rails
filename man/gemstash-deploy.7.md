---
title: gemstash-deploy
date: October 25, 2015
section: 7
...

# Deploying Gemstash

Bundler is here for the rescue to keep Gemstash up to date! Create a `Gemfile`
pointing to Gemstash:
```ruby
# ./Gemfile
source "https://rubygems.org"
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

## Monitoring

Health monitoring is built in to Gemstash using the
[server_health_check-rack][SERVER_HEALTH_CHECK_RACK] gem. If you request
`/health` from your Gemstash instance, you will get a JSON response along with
an HTTP status code indicating success or failure. The JSON response will look
something like this for a success case:
```
{
  "status": {
    "heartbeat": "OK",
    "storage_read": "OK",
    "storage_write": "OK",
    "db_read": "OK",
    "db_write": "OK"
  }
}
```

This request will test storage and database access and report on the
result. Each key in the status can be requested alone to just report on that
status. For example, if you would like a health check that doesn't interact with
storage or the database, you can use `/health/heartbeat` which will always
respond with a success while your Gemstash server is running.

## Downgrading

It is not recommended to go backwards in Gemstash versions. Migrations may have
run that could leave the database in a bad state.

[SERVER_HEALTH_CHECK_RACK]: https://github.com/on-site/server_health_check-rack