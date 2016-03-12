# Private Gems

Stashing private gems in your Gemstash server requires a bit of additional
setup. If you haven't read through the [Quickstart
Guide](../README.md#quickstart-guide), you should do that first. By the end of
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

This new key can `push`, `yank`, and `unyank` gems from your Gemstash server.
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
you've pushed a gem to https://www.rubygems.org, then you will already have a
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

Private gems often require protected fetching. While the feature is still being discussed at here: https://github.com/bundler/gemstash/issues/24, a temporary solution is available through configuring web server.

Depends on your choice of the web server, for example, Nginx has a `basic_auth` module, which helps to setup HTTP Basic Authentication. On the Bundler side, HTTP Basic Auth credentials can be configured through: http://bundler.io/man/gemfile.5.html#CREDENTIALS-credentials

Below is a sample Nginx config with HTTP Basic Auth added to `/private` path:
```
upstream my-gemstash.dev {
  server unix:/home/my-gemstash-folder/shared/sockets/puma.sock fail_timeout=0;
}

server {
  listen 80;
  server_name my-gemstash.dev;
  root /home/my-gemstash-folder/public;

  location / {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;
    proxy_pass http://my-gemstash.dev;
    location ^~ /private {
      auth_basic "Restricted Content";
      auth_basic_user_file /etc/nginx/.htpasswd;
      proxy_pass http://my-gemstash.dev;
    }
  }
}
```
Please follow this [tutorial](https://www.digitalocean.com/community/tutorials/how-to-set-up-password-authentication-with-nginx-on-ubuntu-14-04) if you are not familiar with creating password for `.htpasswd`.
