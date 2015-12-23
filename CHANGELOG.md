## 1.0.0.pre.4 (2015-12-23)

### Upgrade Notes

  Any gems fetched before this release won't be indexed, which means plugins you
  might install can't know about them. These cached gems might also have
  incorrect headers stored (which shouldn't affect bundling). If you wish to
  correct this, you can delete or back up your cache by deleting or moving your
  `~/.gemstash/gem_cache` directory.

### Bugfixes

  - Cached gem and spec headers don't clobber each other ([#68](https://github.com/bundler/gemstash/pull/68), [@smellsblue](https://github.com/smellsblue))

### Features

  - Index cached gems and their upstreams for future use of plugins ([#68](https://github.com/bundler/gemstash/pull/68), [@smellsblue](https://github.com/smellsblue))

## 1.0.0.pre.3 (2015-12-21)

### Bugfixes

  - Fail on missing specified config ([#66](https://github.com/bundler/gemstash/pull/66), [@smellsblue](https://github.com/smellsblue))

## 1.0.0.pre.2 (2015-12-14)

### Upgrade Notes

  - If you pushed any private gems to your Gemstash instance, you will need to run: https://gist.github.com/smellsblue/53f5a6757dcc91ad10bc

### Bugfixes

  - Add --pre option to gemstash installation documentation ([#54](https://github.com/bundler/gemstash/pull/54), [@farukaydin](https://github.com/farukaydin))
  - Fix docs for `gemstash authorize` ([#59](https://github.com/bundler/gemstash/pull/59), [@farukaydin](https://github.com/farukaydin))
  - Refactoring, changed resource metadata `:gemstash_storage_version` to use `:gemstash_resource_version` ([#60](https://github.com/bundler/gemstash/pull/60), [@smellsblue](https://github.com/smellsblue))
  - Fix migrations for utf8 on MySQL >= 5.5 ([#64](https://github.com/bundler/gemstash/pull/64), [@chriseckhardt](https://github.com/chriseckhardt))

### Features

  - Support MySQL as DB backend ([#52](https://github.com/bundler/gemstash/pull/52), [@pcarranza](https://github.com/pcarranza))
  - Add start/stop output ([#58](https://github.com/bundler/gemstash/pull/58), [@farukaydin](https://github.com/farukaydin))
  - Add `gemstash --version` ([#62](https://github.com/bundler/gemstash/pull/62), [@smellsblue](https://github.com/smellsblue))
  - Create the CHANGELOG ([#63](https://github.com/bundler/gemstash/pull/63), [@smellsblue](https://github.com/smellsblue))

## 1.0.0.pre.1 (2015-11-30)

### Features

  - Cache gems from multiple sources
  - Push, yank, and unyank private gems
  - Zero setup dependencies
  - Optionally use Memcached for caching or PostgreSQL for the database
