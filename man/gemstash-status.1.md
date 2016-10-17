---
title: gemstash-status
date: October 28, 2015
section: 1
...

# Name

gemstash-status - Checks status of the Gemstash server

# Synopsis

`gemstash status [--config-file FILE]`

# Description

Checks status of the Gemstash server.

# Options

* `--config-file FILE`:
    Specify the config file to use. If you aren't using the default config file
    at `~/.gemstash/config.yml` or [`~/.gemstash/config.yml.erb`][ERB_CONFIG],
    then you must specify the config file via this option.

[ERB_CONFIG]: ./gemstash-customize.7.md#erb-parsed-config
