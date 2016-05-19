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
<pre>
$ gemstash setup
Where should files go? [~/.gemstash]
Cache with what? [MEMORY, memcached] <strong>memcached</strong>
What is the comma separated Memcached servers? [localhost:11211]
What database adapter? [SQLITE3, postgres] <strong>postgres</strong>
Where is the database? [postgres:///gemstash]
Checking that the cache is available
Checking that the database is available
The database is not available
</pre>

Once you've answered the questions, some checks will be made to ensure the
configuration will work. For example, the database didn't exist in the previous
example, so the command failed and the configuration wasn't saved. If the
command passes, you may provide the `--redo` option to force configuration to be
redone:
<pre>
$ gemstash setup --redo
Where should files go? [~/.gemstash]
Cache with what? [MEMORY, memcached] <strong>memcached</strong>
What is the comma separated Memcached servers? [localhost:11211]
What database adapter? [SQLITE3, postgres]
Checking that the cache is available
Checking that the database is available
You are all setup!
</pre>

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
The default `:db_adapter` is [`sqlite3`](https://www.sqlite.org/), which will
use a database file located within your `:base_path`. The database file will
always be named `gemstash.db`.

You may also use [`postgres`](http://www.postgresql.org/) for your
`:db_adapter`. When using PostgreSQL, you need to specify the `:db_url` to point
to an existing database. Here is an example configuration to use the `postgres`
adapter:
```yaml
# ~/.gemstash/config.yml
---
:db_adapter: postgres
:db_url: postgres:///gemstash
```

Regardless of the adapter you choose, the database will automatically migrate to
your version of Gemstash whenever the database is needed. Except for `sqlite3`,
you only need to ensure the database exists and Gemstash will do the rest.

## Cache

Certain things (like dependencies) are cached in memory. This avoids web calls
to the gem source, and database calls for private gems. The memory cache can
optionally be swapped out with a [Memcached](http://memcached.org/) server (or
cluster of servers). To use Memcached, you must update the `:cache_type`
configuration key to be `memcached`, and provide the servers via the
`:memcached_servers` configuration key:
```yaml
# ~/.gemstash/config.yml
---
:cache_type: memcached
:memcached_servers: memcached1.local:11211,memcached2.local:11211
```

Note that the `:memcached_servers` requires a comma separated list of servers.
All caching lasts for 30 minutes.

## Server

Gemstash uses [Puma](http://puma.io/) and [Rack](http://rack.github.io/) as the
server. Alternate server configurations are not currently supported, but you can
take a look at the [Puma configuration](../lib/gemstash/puma.rb) and the [rackup
file](../lib/gemstash/config.ru) for inspiration.

While the server is not customizable, the way Gemstash binds the port can be
changed. To change the binding, update the `:bind` configuration key:
```yaml
# ~/.gemstash/config.yml
---
:bind: tcp://0.0.0.0:4242
```

This maps directly to the [Puma bind
flag](https://github.com/puma/puma#binding-tcp--sockets), and will support
anything valid for that flag.

## Environment Variables

You may also create a `~/.gemstash/config.yml.erb` file. If present this will be used instead of `~/.gemstash/config.yml`.
With this you can use Environment Variables in the config:

```yaml
# ~/.gemstash/config.yml
---
:db_adapter: postgres
:db_url: <%= DATABASE_URL %>
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
