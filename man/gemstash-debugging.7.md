---
title: gemstash-debugging
date: October 28, 2015
section: 7
...

# Debugging Gemstash

If you are finding Gemstash isn't behaving as you would expect, you might want
to start by looking at the server log. You can find the log at `server.log`
within your base directory. By default, this will be at
`~/.gemstash/server.log`.

You might find it easier to view the log directly in your terminal. If you run
Gemstash [in non-daemonized form][START_OPTIONS], the log will be
output directly to standard out:
```
$ gemstash start --no-daemonize
```

You can also [check the status][STATUS] of the server:
```
$ gemstash status
```

The server status is checked by passing through to [pumactl][PUMACTL].

If you find a bug, please don't hesitate to [open a bug report][CONTRIBUTING]!

[START_OPTIONS]: ./gemstash-start.1.md#options
[STATUS]: ./gemstash-status.1.md
[PUMACTL]: https://github.com/puma/puma#pumactl
[CONTRIBUTING]: https://github.com/bundler/gemstash#contributing
