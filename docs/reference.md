# Reference

## Configuration

**Example:**
```yaml
# ~/.gemstash/config.yml
---
:base_path: "/var/gemstash"
:cache_type: memcached
:memcached_servers: localhost:11211
:db_adapter: postgres
:db_url: postgres:///gemstash
:rubygems_url: https://my.gem-source.local
:port: 4242
```

### `:base_path`

**Default value:** `~/.gemstash`

**Valid values:** Any valid path

**Description**<br />
Specifies where to store local files like the server log, cached gem files, and
the database (when using SQLite). If the default is being used, the directory
will be created if it does not exist. Any other directory needs to be created
ahead of time and be writable to the Gemstash server process. Specifying the
`:base_path` via [`gemstash setup`](reference.md#setup) will create the
directory for you.

### `:cache_type`

**Default value:** `memory`

**Valid values:** `memory`, `memcached`

**Description**<br />
Specifies how to cache values other than gem files (such as gem dependencies).
`memory` will use an in memory cache while `memcached` will point to 1 or more
Memcached servers. Use the `:memcached_servers` configuration key for specifying
where the Memcached server(s) are.

### `:memcached_servers`

**Default value:** `localhost:11211`

**Valid values:** A comma delimited list of Memcached servers

**Description**<br />
Specifies the Memcached servers to connect to when using `memcached` for the
`:cache_type`. Only used when `memcached` is used for `:cache_type`.

### `:db_adapter`

**Default value:** `sqlite3`

**Valid values:** `sqlite3`, `postgres`

**Description**<br />
Specifies what database adapter to use. When `sqlite3` is used, the database
will be located at `gemstash.db` within the directory specified by `:base_path`.
The database will automatically be created when using `sqlite3`. When `postgres`
is used, the database to connect to must be specified in the `:db_url`
configuration key. The database must already be created when using `postgres`.

### `:db_url`

**Default value:** None

**Valid values:** A valid database URL for the [Sequel
gem](http://sequel.jeremyevans.net/)

**Description**<br />
Specifies the database to connect to when using `postgres` for the
`:db_adapter`. Only used when `postgres` is used for `:db_adapter`.

### `:rubygems_url`

**Default value:** `https://www.rubygems.org`

**Valid values:** A valid gem source URL

**Description**<br />
Specifies the default gem source URL. When any API endpoint is called without a
`/private` or `/upstream/<url>` prefix, this URL will be used to fetch the
result. This value can be safely changed even if there are already gems stashed
for the previous value.

### `:port`

**Default value:** `9292`

**Valid values:** Any valid port that Gemstash can open

**Description**<br />
Specifies the port to open when Gemstash starts. Keep in mind the user starting
Gemstash needs to have access to open this port. If you use a value below 1024,
you will need to run Gemstash as the root user.

## Authorize

## Start

## Stop

## Setup
