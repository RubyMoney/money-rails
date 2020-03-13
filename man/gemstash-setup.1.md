---
title: gemstash-setup
date: October 9, 2015
section: 1
...

# Name

gemstash-setup - Customize your Gemstash configuration interactively

# Synopsis

`gemstash setup [--redo] [--debug] [--config-file FILE]`

# Description

Customize your Gemstash configuration interactively. This will save your config
file, but only if a few checks pass after you've provided your answers.

## Usage

```
gemstash setup
gemstash setup --redo
gemstash setup --config-file <file>
```

# Options

* `--redo`:
    Redo the configuration. This does nothing the first time `gemstash setup` is
    run. If you want to change your configuration using `gemstash setup` after
    you've run it before, you must provide this option, otherwise Gemstash will
    simply indicate your setup is complete.

* `--debug`:
    Output additional information if one of the checks at the end of setup fails.
    This will do nothing if all checks pass.

* `--config-file FILE`:
    Specify the config file to write to. Without this option, your configuration
    will be written to `~/.gemstash/config.yml`. If you write to a custom
    location, you will need to pass the `--config-file` option to all Gemstash
    commands. If you plan to use [ERB in your config file][ERB_CONFIG], you
    might want to use `~/.gemstash/config.yml.erb`.

[ERB_CONFIG]: ./gemstash-customize.7.md#erb-parsed-config
