# Debugging Gemstash

If you are finding Gemstash isn't behaving as you would expect, you might want
to start by looking at the server log. You can find the log at `server.log`
within your base directory. By default, this will be at
`~/.gemstash/server.log`.

You might find it easier to view the log directly in your terminal. If you run
Gemstash [in non-daemonized form](reference.md#--no-daemonize), the log will be
output directly to standard out:
```
$ gemstash start --no-daemonize
```

You can also [check the status](reference.md#status) of the server:
```
$ gemstash status
```

The server status is checked by passing through to
[pumactl](https://github.com/puma/puma#pumactl).

If you find a bug, please don't hesitate to [open a bug
report](../README.md#contributing)!
