---
title: gemstash-start
date: October 9, 2015
section: 1
...

# Name

gemstash-start - Starts the Gemstash server

# Synopsis

`gemstash start [--no-daemonize] [--config-file FILE]`

# Description

Starts the Gemstash server.

# Options

* `--config-file FILE`:
    Specify the config file to use. If you aren't using the default config file at
    `~/.gemstash/config.yml`, then you must specify the config file via this option.

* `--no-daemonize`:
    The Gemstash server daemonizes itself by default. Provide this option to instead
    run the server until `Ctrl-C` is typed. When not daemonized, the log will be
    output to standard out.
