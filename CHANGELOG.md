## 1.0.0.pre.2 (2015-12-10)

### Upgrade Notes

  - If you pushed any private gems to your Gemstash instance, you will need to run: https://gist.github.com/smellsblue/53f5a6757dcc91ad10bc

### Bugfixes

  - Add --pre option to gemstash installation documentation ([#54](https://github.com/bundler/gemstash/pull/54), [@farukaydin](https://github.com/farukaydin))
  - Fix docs for `gemstash authorize` ([#59](https://github.com/bundler/gemstash/pull/59), [@farukaydin](https://github.com/farukaydin))
  - Refactoring, changed resource metadata `:gemstash_storage_version` to use `:gemstash_resource_version` ([#60](https://github.com/bundler/gemstash/pull/60), [@smellsblue](https://github.com/smellsblue))

### Features

  - Support MySQL as DB backend ([#52](https://github.com/bundler/gemstash/pull/52), [@pcarranza](https://github.com/pcarranza))
  - Add start/stop output ([#58](https://github.com/bundler/gemstash/pull/58), [@farukaydin](https://github.com/farukaydin))

## 1.0.0.pre.1 (2015-11-30)

### Features

  - Cache gems from multiple sources
  - Push, yank, and unyank private gems
  - Zero setup dependencies
  - Optionally use Memcached for caching or PostgreSQL for the database
