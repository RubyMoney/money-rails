
Table of Contents
=================

  * [Reference](#reference)
    * [Configuration](#configuration)
      * [:base_path](#base_path)
      * [:cache_type](#cache_type)
      * [:memcached_servers](#memcached_servers)
      * [:db_adapter](#db_adapter)
      * [:db_url](#db_url)
      * [:rubygems_url](#rubygems_url)
      * [:bind](#bind)
      * [:protected_fetch](#protected_fetch)
      * [:fetch_timeout](#fetch_timeout)
    * [Authorize](#authorize)
      * [Usage](#usage)
      * [Arguments](#arguments)
      * [Options](#options)
        * [--config-file](#--config-file)
        * [--key](#--key)
        * [--remove](#--remove)
    * [Start](#start)
      * [Usage](#usage-1)
      * [Options](#options-1)
        * [--config-file](#--config-file-1)
        * [--no-daemonize](#--no-daemonize)
    * [Stop](#stop)
      * [Usage](#usage-2)
      * [Options](#options-2)
        * [--config-file](#--config-file-2)
    * [Status](#status)
      * [Usage](#usage-3)
      * [Options](#options-3)
        * [--config-file](#--config-file-3)
    * [Setup](#setup)
      * [Usage](#usage-4)
      * [Options](#options-4)
        * [--redo](#--redo)
        * [--debug](#--debug)
        * [--config-file](#--config-file-4)
    * [Version](#version)
      * [Usage](#usage-5)



---

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
:bind: tcp://0.0.0.0:4242
:protected_fetch: true
:fetch_timeout: 20
```

### :base_path

**Default value:** `~/.gemstash`

**Valid values:** Any valid path

**Description**<br />
Specifies where to store local files like the server log, cached gem files, and
the database (when using SQLite). If the default is being used, the directory
will be created if it does not exist. Any other directory needs to be created
ahead of time and be writable to the Gemstash server process. Specifying the
`:base_path` via [`gemstash setup`](reference.md#setup) will create the
directory for you.

### :cache_type

**Default value:** `memory`

**Valid values:** `memory`, `memcached`

**Description**<br />
Specifies how to cache values other than gem files (such as gem dependencies).
`memory` will use an in memory cache while `memcached` will point to 1 or more
Memcached servers. Use the `:memcached_servers` configuration key for specifying
where the Memcached server(s) are.

### :memcached_servers

**Default value:** `localhost:11211`

**Valid values:** A comma delimited list of Memcached servers

**Description**<br />
Specifies the Memcached servers to connect to when using `memcached` for the
`:cache_type`. Only used when `memcached` is used for `:cache_type`.

### :db_adapter

**Default value:** `sqlite3`

**Valid values:** `sqlite3`, `postgres`

**Description**<br />
Specifies what database adapter to use. When `sqlite3` is used, the database
will be located at `gemstash.db` within the directory specified by `:base_path`.
The database will automatically be created when using `sqlite3`. When `postgres`
is used, the database to connect to must be specified in the `:db_url`
configuration key. The database must already be created when using `postgres`.

### :db_url

**Default value:** None

**Valid values:** A valid database URL for the [Sequel
gem](http://sequel.jeremyevans.net/)

**Description**<br />
Specifies the database to connect to when using `postgres` for the
`:db_adapter`. Only used when `postgres` is used for `:db_adapter`.

### :rubygems_url

**Default value:** `https://rubygems.org`

**Valid values:** A valid gem source URL

**Description**<br />
Specifies the default gem source URL. When any API endpoint is called without a
`/private` or `/upstream/<url>` prefix, this URL will be used to fetch the
result. This value can be safely changed even if there are already gems stashed
for the previous value.

### :bind

**Default value:** `tcp://0.0.0.0:9292`

**Valid values:** Any valid binding that [is supported by
Puma](https://github.com/puma/puma#binding-tcp--sockets)

**Description**<br />
Specifies the binding used to start the Gemstash server. Keep in mind the user
starting Gemstash needs to have access to bind in this manner. For example, if
you use a port below 1024, you will need to run Gemstash as the root user.

### :protected_fetch

**Default value:** `false`

**Valid values:** Boolean values `true` or `false`

**Description**<br />
Tells Gemstash to authenticate via API Key before allowing the fetching of Private gems and specs. Default is un-authenticated download of Private gems and specs.

### :fetch_timeout

**Default value:** `20`

**Valid values:** Integer values `1` to `9999`+

**Description**<br />
The timeout setting for fetching gems. Fetching gems over a slow connection may cause timeout errors. If you experience timeout errors you may want to increase this value. The default is `20` seconds.

## Authorize

Adds or removes authorization to interact with privately stored gems.

### Usage

```
gemstash authorize
gemstash authorize push yank
gemstash authorize yank unyank --key <secure-key>
gemstash authorize --remove --key <secure-key>
```

### Arguments

Any arguments will be used as specific permissions. Valid permissions include
`push`, `yank`, `unyank`, and `fetch`. If no permissions are provided, then all
permissions will be granted (including any that may be added in future versions
of Gemstash).

### Options

#### --config-file

**Usage:** `--config-file <file>`

**Description**<br />
Specify the config file to use. If you aren't using the default config file at
`~/.gemstash/config.yml` or [`~/.gemstash/config.yml.erb`](https://github.com/bundler/gemstash/blob/master/docs/config.md#erb-parsed-config)), then you must specify the config file via this option.

#### --key

**Usage:** `--key <secure-key>`

**Description**<br />
Specify the API key to affect. This should be the actual key value, not a name.
This option is required when using `--remove` but is optional otherwise. If
adding an authorization, using this will either create or update the permissions
for the specified API key. If missing, a new API key will always be generated.
Note that a key can only have a maximum length of 255 chars.

#### --remove

**Usage:** `--remove`

**Description**<br />
Remove an authorization rather than add or update one. When removing, permission
values are not allowed. The `--key <secure-key>` option is required.

## Start

Starts the Gemstash server.

### Usage

```
gemstash start
gemstash start --no-daemonize
```

### Options

#### --config-file

**Usage:** `--config-file <file>`

**Description**<br />
Specify the config file to use. If you aren't using the default config file at
`~/.gemstash/config.yml` (or [`~/.gemstash/config.yml.erb`](https://github.com/bundler/gemstash/blob/master/docs/config.md#erb-parsed-config)), then you must specify the config file via this option.

#### --no-daemonize

**Usage:** `--no-daemonize`

**Description**<br />
The Gemstash server daemonizes itself by default. Provide this option to instead
run the server until `Ctrl-C` is typed. When not daemonized, the log will be
output to standard out.

## Stop

Stops the Gemstash server.

### Usage

```
gemstash stop
```

### Options

#### --config-file

**Usage:** `--config-file <file>`

**Description**<br />
Specify the config file to use. If you aren't using the default config file at
`~/.gemstash/config.yml` or [`~/.gemstash/config.yml.erb`](https://github.com/bundler/gemstash/blob/master/docs/config.md#erb-parsed-config)), then you must specify the config file via this option.

## Status

Checks status of the Gemstash server.

### Usage

```
gemstash status
```

### Options

#### --config-file

**Usage:** `--config-file <file>`

**Description**<br />
Specify the config file to use. If you aren't using the default config file at
`~/.gemstash/config.yml` or [`~/.gemstash/config.yml.erb`](https://github.com/bundler/gemstash/blob/master/docs/config.md#erb-parsed-config)), then you must specify the config file via this option.

## Setup

Customize your Gemstash configuration interactively. This will save your config
file, but only if a few checks pass after you've provided your answers.

### Usage

```
gemstash setup
gemstash setup --redo
gemstash setup --config-file <file>
```

### Options

#### --redo

**Usage:** `--redo`

**Description**<br />
Redo the configuration. This does nothing the first time `gemstash setup` is
run. If you want to change your configuration using `gemstash setup` after
you've run it before, you must provide this option, otherwise Gemstash will
simply indicate your setup is complete.

#### --debug

**Usage:** `--debug`

**Description**<br />
Output additional information if one of the checks at the end of setup fails.
This will do nothing if all checks pass.

#### --config-file

**Usage:** `--config-file <file>`

**Description**<br />
Specify the config file to write to. Without this option, your configuration
will be written to `~/.gemstash/config.yml` or [`~/.gemstash/config.yml.erb`](https://github.com/bundler/gemstash/blob/master/docs/config.md#erb-parsed-config)). If you write to a custom location,
you will need to pass the `--config-file` option to all Gemstash commands.

## Version

Show what version of Gemstash you are using.

### Usage

```
gemstash version
gemstash --version
gemstash -v
```

---

Table of contents thanks to [gh-md-toc](https://github.com/ekalinin/github-markdown-toc).
