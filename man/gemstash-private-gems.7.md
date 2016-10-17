---
title: gemstash-private-gems
date: October 8, 2015
section: 7
...

# Private Gems

Stashing private gems in your Gemstash server requires a bit of additional
setup. If you haven't read through the [Quickstart
Guide][README_QUICKSTART], you should do that first. By the end of
this guide, you will be able to interact with your Gemstash server to store and
retrieve your private gems.

## Authorizing

**IMPORTANT NOTE:** Do not use the actual key value in this document, otherwise
your Gemstash server will be vulnerable to anyone who wants to try to use the
key against your server. Instead of the key value here, use whatever key is
generated from running the commands.

In order to push a gem to your Gemstash server, you need to first create an API
key. Utilize the `gemstash authorize` command to create the API key:
```
$ gemstash authorize
Your new key is: e374e237fdf5fa5718d2a21bd63dc911
```

This new key can `push`, `yank`, `unyank`, and `fetch` gems from your Gemstash server.
Run `gemstash authorize` with just the permissions you want to limit what the
key will be allowed to do. You can similarly update a specific key by providing
it via the `--key` option:
```
$ gemstash authorize push yank --key e374e237fdf5fa5718d2a21bd63dc911
```

When no permissions are provided (like the first example), the key will be
authorized for all permissions. Leave the key authorized with everything if you
want to use it to try all private gem interactions:
```
$ gemstash authorize --key e374e237fdf5fa5718d2a21bd63dc911
```

With the key generated, you'll need to tell Rubygems about your new key. If
you've pushed a gem to https://rubygems.org, then you will already have a
credentials file to add the key to. If not, run the following commands before
modifying the credentials file:
```
$ mkdir -p ~/.gem
$ touch ~/.gem/credentials
$ chmod 0600 ~/.gem/credentials
```

Add your new key to credentials such that it looks something like this (but make
sure not to remove any existing keys):
```yaml
# ~/.gem/credentials
---
:test_key: e374e237fdf5fa5718d2a21bd63dc911
```

The name `test_key` can be anything you want, but you will need to remember it
and use it again later in this guide for the `--key` option.

## Creating a Test Gem

You'll need a test gem before you can play with private gems on your Gemstash
server. If you have a gem you can use, move along to the next section. You can
start by instantiating a test gem via Bundler:
```
$ bundle gem private-example
```

You'll need to add a summary and description to the new gem's gemspec file in
order to successfully build it. Once you've built the gem, you will be ready to
push the new gem.
```
$ cd private-example
$ rake build
```

You will now have a gem at `private-example/pkg/private-example-0.1.0.gem`.

## Pushing

If your Gemstash server isn't running, go ahead and start it:
```
$ gemstash start
```

Push your test gem using Rubygems:
```
$ gem push --key test_key --host http://localhost:9292/private pkg/private-example-0.1.0.gem
```

The `/private` portion of the `--host` option tells Gemstash you are interacting
with the private gems. Gemstash will not let you push, yank, or unyank from
anything except `/private`.

## Bundling

Once your gem is pushed to your Gemstash server, you are ready to bundle it.
Create a `Gemfile` and specify the gem. You will probably want to wrap the
private gem in a source block, and let the rest of Gemstash handle all other
gems:
```ruby
# ./Gemfile
source "http://localhost:9292"
gem "rubywarrior"

source "http://localhost:9292/private" do
  gem "private-example"
end
```

Notice that the Gemstash server points to `/private` again when installing your
private gem. Go ahead and bundle to install your new private gem:
```
$ bundle
```

## Yanking

If you push a private gem by accident, you can yank the gem with Rubygems:
```
$ RUBYGEMS_HOST=http://localhost:9292/private gem yank --key test_key private-example --version 0.1.0
```

Like with pushing, the `/private` portion of the host option tells Gemstash you
are interacting with private gems. Gemstash will only let you yank from
`/private`. Unlike pushing, Rubygems doesn't support `--host` for yank and
unyank (yet), so you need to specify the host via the `RUBYGEMS_HOST`
environment variable.

## Unyanking

If you yank a private gem by accident, you can unyank the gem with Rubygems:
```
$ RUBYGEMS_HOST=http://localhost:9292/private gem yank --key test_key private-example --version 0.1.0 --undo
```

Like with pushing and yanking, the `/private` portion of the host option tells
Gemstash you are interacting with private gems. Gemstash will only let you
unyank from `/private`. Unlike pushing, Rubygems doesn't support `--host` for
unyank and yank (yet), so you need to specify the host via the `RUBYGEMS_HOST`
environment variable.

## Protected Fetching

By default, private gems and specs can be accessed without authentication.

Private gems often require protected fetching. For backwards compatibility this
is disabled by default, but can be enabled via `$ gemstash setup` command.

When protected fetching is enabled API keys with the permissions `all` or
`fetch` can be used to download gems and specs.

On the Bundler side, there are a few ways to configure credentials for a given
gem source:

Add credentials globally:

```
$ bundle config my-gemstash.dev api_key
```

Add credentials in Gemfile:

```
source "https://api_key@my-gemstash.dev"
```

However, it's not a good practice to commit credentials to source control. A
recommended solution is to use Bundler's [configuration keys][CONFIG_KEYS],
e.g.:

```
$ export BUNDLE_MYGEMSTASH__DEV=api_key
```

Behind the scene, Bundler will pick up the ENV var according to the host name
(e.g. mygemstash.dev) and add to `URI.userinfo` for making requests.

The API key is treated as a HTTP Basic Auth username and any HTTP Basic password
supplied will be ignored.

[README_QUICKSTART]: ./gemstash-readme.7.md#quickstart-guide
[CONFIG_KEYS]: http://bundler.io/man/bundle-config.1.html#CONFIGURATION-KEYS
