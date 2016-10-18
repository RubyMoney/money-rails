---
title: gemstash-configuration
date: October 13, 2015
section: 5
...

# Name

gemstash-configuration

# Synopsis

```yaml
# ~/.gemstash/config.yml
---
:base_path: "/var/gemstash"
:cache_type: memcached
:memcached_servers: localhost:11211
:db_adapter: postgres
:db_url: postgres:///gemstash
:rubygems_url: https://my.gem-source.local
:bind: tcp://0.0.0.0:4242
:protected_fetch: true
:fetch_timeout: 10
:log_file: gemstash.log
```

# Base Path

`:base_path`

Specifies where to store local files like the server log, cached gem files, and
the database (when using SQLite). If the default is being used, the directory
will be created if it does not exist. Any other directory needs to be created
ahead of time and be writable to the Gemstash server process. Specifying the
`:base_path` via [`gemstash setup`][SETUP] will create the directory for you.

## Default value

`~/.gemstash`

## Valid values

Any valid path

# Cache Type

`:cache_type`

Specifies how to cache values other than gem files (such as gem dependencies).
`memory` will use an in memory cache while `memcached` will point to 1 or more
Memcached servers. Use the `:memcached_servers` configuration key for specifying
where the Memcached server(s) are.

## Default value

`memory`

## Valid values

`memory`, `memcached`

# Memcached Servers

`:memcached_servers`

Specifies the Memcached servers to connect to when using `memcached` for the
`:cache_type`. Only used when `memcached` is used for `:cache_type`.

## Default value

`localhost:11211`

## Valid values

A comma delimited list of Memcached servers

# DB Adapter

`:db_adapter`

Specifies what database adapter to use. When `sqlite3` is used, the database
will be located at `gemstash.db` within the directory specified by `:base_path`.
The database will automatically be created when using `sqlite3`. When
`postgres`, `mysql`, or `mysql2` is used, the database to connect to must be
specified in the `:db_url` configuration key. The database must already be
created when using anything other than `sqlite3`.

## Default value

`sqlite3`

## Valid values

`sqlite3`, `postgres`, `mysql`, `mysql2`

# DB URL

`:db_url`

Specifies the database to connect to when using `postgres`, `mysql`, or `mysql2`
for the `:db_adapter`. Only used when the `:db_adapter` is not `sqlite3`.

## Default value

None

## Valid values

A valid database URL for the [Sequel gem][SEQUEL]

# Rubygems URL

`:rubygems_url`

Specifies the default gem source URL. When any API endpoint is called without a
`/private` or `/upstream/<url>` prefix, this URL will be used to fetch the
result. This value can be safely changed even if there are already gems stashed
for the previous value.

## Default value

`https://rubygems.org`

## Valid values

A valid gem source URL

# Bind Address

`:bind`

Specifies the binding used to start the Gemstash server. Keep in mind the user
starting Gemstash needs to have access to bind in this manner. For example, if
you use a port below 1024, you will need to run Gemstash as the root user.

## Default value

`tcp://0.0.0.0:9292`

## Valid values

Any valid binding that [is supported by Puma][PUMA_BINDING]

# Protected Fetch

`:protected_fetch`

Tells Gemstash to authenticate via an API key before allowing the fetching of
private gems and specs. The default behavior is to allow unauthenticated
download of private gems and specs.

## Default value

`false`

## Valid values

Boolean values `true` or `false`

# Fetch Timeout

`:fetch_timeout`

The timeout setting for fetching gems. Fetching gems over a slow connection may
cause timeout errors. If you experience timeout errors, you may want to increase
this value. The default is `20` seconds.

## Default value

`20`

## Valid values

Integer value with a minimum of `1`

# Log File

`:log_file`

Indicates the name of the file to use for logging. The file will be placed in
the [base path][BASE_PATH].

## Default value

`server.log`

## Valid values

Any valid file name

[SETUP]: ./gemstash-setup.1.md
[SEQUEL]: http://sequel.jeremyevans.net/
[PUMA_BINDING]: https://github.com/puma/puma#binding-tcp--sockets
[BASE_PATH]: ./gemstash-configuration.5.md#base-path
