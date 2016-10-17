---
title: gemstash-stop
date: October 9, 2015
section: 1
...

# Name

gemstash-stop - Stops the Gemstash server

# Synopsis

`gemstash stop [--config-file FILE]`

# Description

Stops the Gemstash server.

# Options

* `--config-file FILE`:
    Specify the config file to use. If you aren't using the default config file
    at `~/.gemstash/config.yml` or [`~/.gemstash/config.yml.erb`][ERB_CONFIG],
    then you must specify the config file via this option.

[ERB_CONFIG]: ./gemstash-customize.7.md#erb-parsed-config
