---
title: gemstash-customize
date: October 28, 2015
section: 7
...

# Customizing the Server

Although Gemstash is designed for as minimal setup as possible, there may be
times you will want to change some of the default configuration. By the end of
this guide, you will be able to customize some of the Gemstash behavior,
including where files are stored, what database Gemstash uses, and how Gemstash
caches certain requests.

## Setup

Several customizable options are available via an interactive Gemstash command.
Run `gemstash setup` and answer the questions it provides (a blank answer will
use the default value):

> $ gemstash setup\
> Where should files go? [~/.gemstash]\
> Cache with what? [MEMORY, memcached] **memcached**\
> What is the comma separated Memcached servers? [localhost:11211]\
> What database adapter? [SQLITE3, postgres, mysql, mysql2] **postgres**\
> Where is the database? [postgres:///gemstash]\
> Checking that the cache is available\
> Checking that the database is available\
> The database is not available\

Once you've answered the questions, some checks will be made to ensure the
configuration will work. For example, the database didn't exist in the previous
example, so the command failed and the configuration wasn't saved. If the
command passes, you may provide the `--redo` option to force configuration to be
redone:

> $ gemstash setup --redo\
> Where should files go? [~/.gemstash]\
> Cache with what? [MEMORY, memcached] **memcached**\
> What is the comma separated Memcached servers? [localhost:11211]\
> What database adapter? [SQLITE3, postgres, mysql, mysql2]\
> Checking that the cache is available\
> Checking that the database is available\
> You are all setup!\

Once all checks have passed, Gemstash will store your answers in the
configuration file located at `~/.gemstash/config.yml`.

## Files

Storage in Gemstash defaults to `~/.gemstash` unless otherwise specified. You
can change this in your config file via the `:base_path` key:
```yaml
# ~/.gemstash/config.yml
---
:base_path: "/var/gemstash"
```

When customizing the `base_path`, the directory must exist, otherwise Gemstash
will fail to run. Thus, if you want to use `/var/gemstash` like in the previous
example, make sure to `mkdir /var/gemstash` and grant access to the directory
for the user you run Gemstash with.

## Database

The `:db_adapter` configuration key specifies what database you will be using.
The default `:db_adapter` is [`sqlite3`][SQLITE], which will
use a database file located within your `:base_path`. The database file will
always be named `gemstash.db`.

You may also use [`postgres`][POSTGRES], [`mysql`][MYSQL], or [`mysql2`][MYSQL2]
for your `:db_adapter`. When using any of these options, you need to specify the
`:db_url` to point to an existing database. Here is an example configuration to
use the `postgres` adapter:
```yaml
# ~/.gemstash/config.yml
---
:db_adapter: postgres
:db_url: postgres:///gemstash
:db_connection_options: # Sequel.connect options
  :connect_timeout: 10
  :read_timeout: 5
  :timeout: 30
```

Regardless of the adapter you choose, the database will automatically migrate to
your version of Gemstash whenever the database is needed. You only need to
ensure the database exists and Gemstash will do the rest, except for `sqlite3`
(for which Gemstash will also create the database for you).

## Cache

Certain things (like dependencies) are cached in memory. This avoids web calls
to the gem source, and database calls for private gems.

```yaml
# ~/.gemstash/config.yml
---
:cache_type: memory
:cache_max_size: 2000
```

This configuration uses the default `memory` cache, and has increased the
`cache_max_size` setting from its default of 500 items.

The memory cache can optionally be swapped out with a [Memcached][MEMCACHED]
server (or cluster of servers).

To use Memcached, use the `memcached` `:cache_type` configuration.

Provide the servers as a comma-separated list to the `:memcached_servers`
configuration key:

```yaml
# ~/.gemstash/config.yml
---
:cache_type: memcached
:memcached_servers: memcached1.local:11211,memcached2.local:11211
:cache_expiration: 1800
```

All caching expires in `cache_expiration` number of seconds. Default is 1800 seconds
(30 minutes). This option applies to all caching.

## Server

Gemstash uses [Puma][PUMA] and [Rack][RACK] as the
server. Alternate server configurations are not currently supported, but you can
take a look at the [Puma configuration][PUMA_CONFIG] and the [rackup file][RACKUP_FILE]
for inspiration.

While the server is not customizable, the way Gemstash binds the port can be
changed. To change the binding, update the `:bind` configuration key:
```yaml
# ~/.gemstash/config.yml
---
:bind: tcp://0.0.0.0:4242
```

This maps directly to the [Puma bind flag][PUMA_BIND], and will support
anything valid for that flag.

The number of threads Puma uses is also customizable via the `:puma_threads`
configuration key. The default is `16`.

## Protected Fetch

Gemstash by default allows unauthenticated access for private
gems. Authenticated access is available via the `:protected_fetch` configuration
key.

```yaml
# ~/.gemstash/config.yml
---
:protected_fetch: true
```

More details on [protected_fetch are here][PROTECTED_FETCH].

## Fetch Timeout

The default fetch timeout is 20 seconds. Use the `:fetch_timeout` configuration
key to change it.

```yaml
---
:fetch_timeout: 20
```

## Config File Location

By default, configuration for Gemstash will be at `~/.gemstash/config.yml`. This
can be changed by providing the `--config-file` option to the various Gemstash
commands:
```
$ gemstash setup --config-file ./gemstash-config.yml
$ gemstash authorize --config-file ./gemstash-config.yml
$ gemstash start --config-file ./gemstash-config.yml
$ gemstash stop --config-file ./gemstash-config.yml
$ gemstash status --config-file ./gemstash-config.yml
```

When providing `--config-file` to `gemstash setup`, the provided file will be
output to with the provided configuration. **This will overwrite** any existing
configuration. If the file doesn't exist when providing `--config-file` to
`gemstash start`, `gemstash stop`, `gemstash status`, and `gemstash authorize`,
the default configuration will be used.

### ERB parsed config

You may also create a `~/.gemstash/config.yml.erb` file. If present, this will
be used instead of `~/.gemstash/config.yml`. For example, with this you can use
environment variables in the config:

```yaml
# ~/.gemstash/config.yml.erb
---
:db_adapter: postgres
:db_url: <%= ENV["DATABASE_URL"] %>
```

[SQLITE]: https://www.sqlite.org/
[POSTGRES]: http://www.postgresql.org/
[MYSQL]: http://www.mysql.com/
[MYSQL2]: http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html#label-mysql2
[MEMCACHED]: http://memcached.org/
[PUMA]: http://puma.io/
[RACK]: http://rack.github.io/
[PUMA_CONFIG]: https://github.com/bundler/gemstash/blob/master/lib/gemstash/puma.rb
[RACKUP_FILE]: https://github.com/bundler/gemstash/blob/master/lib/gemstash/config.ru
[PUMA_BIND]: https://github.com/puma/puma#binding-tcp--sockets
[PROTECTED_FETCH]: ./gemstash-private-gems.7.md#protected-fetching
