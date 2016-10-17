## master (unreleased)

### Bugfixes

  - Gracefully handle empty configuration files ([#97](https://github.com/bundler/gemstash/pull/97), [@rjocoleman](https://github.com/rjocoleman))
  - Remove bundler-audit since we don't commit our Gemfile.lock ([#98](https://github.com/bundler/gemstash/pull/98), [@smellsblue](https://github.com/smellsblue))
  - Clarify what is being cached for 30 minutes ([#108](https://github.com/bundler/gemstash/pull/108), [@Nowaker](https://github.com/Nowaker))

### Features

  - Add support for mysql2 adapter ([#71](https://github.com/bundler/gemstash/pull/71), [@chriseckhardt](https://github.com/chriseckhardt))
  - Allow logging to a different file ([#74](https://github.com/bundler/gemstash/pull/74), [@mrchucho](https://github.com/mrchucho))
  - Document temporary protected fetch solution ([#80](https://github.com/bundler/gemstash/pull/80), [@taoza](https://github.com/taoza))
  - Make gem fetch timeout configurable ([#81](https://github.com/bundler/gemstash/pull/81), [@midwire](https://github.com/midwire))
  - Document fallback timeout for when Gemstash is down ([#88](https://github.com/bundler/gemstash/pull/88), [@parndt](https://github.com/parndt))
  - Allow ERB parsed config file via `.erb` extension ([#90](https://github.com/bundler/gemstash/pull/90), [@jiexinhuang](https://github.com/jiexinhuang), [@rjocoleman](https://github.com/rjocoleman))
  - Improve code climate ([#92](https://github.com/bundler/gemstash/pull/92), [@smellsblue](https://github.com/smellsblue))
  - Refactor authorization ([#93](https://github.com/bundler/gemstash/pull/93), [@smellsblue](https://github.com/smellsblue), [@rjocoleman](https://github.com/rjocoleman))
  - Add protected fetch for private gems ([#94](https://github.com/bundler/gemstash/pull/94), [@rjocoleman](https://github.com/rjocoleman))

## 1.0.3 (2016-10-15)

### Bugfixes

  - Fix JRuby build ([#110](https://github.com/bundler/gemstash/pull/110), [@smellsblue](https://github.com/smellsblue))
  - Fix nil error when gems are fetched for the first time concurrently ([#111](https://github.com/bundler/gemstash/pull/111), [@smellsblue](https://github.com/smellsblue))

### Features

  - Embedded documentation via `gemstash help` ([#109](https://github.com/bundler/gemstash/pull/109), [@smellsblue](https://github.com/smellsblue))

## 1.0.2 (2016-07-07)

### Bugfixes

  - Fix broken JRuby build ([#91](https://github.com/bundler/gemstash/pull/91), [@smellsblue](https://github.com/smellsblue))
  - Drop www.rubygems.org in favor of rubygems.org ([#101](https://github.com/bundler/gemstash/pull/101), [@smellsblue](https://github.com/smellsblue))
  - Redirect /versions and /info/* to index.rubygems.org ([#102](https://github.com/bundler/gemstash/pull/102), [@smellsblue](https://github.com/smellsblue))

## 1.0.1 (2016-02-23)

### Bugfixes

  - Don't pass along the Content-Length header ([#77](https://github.com/bundler/gemstash/pull/77), [@smellsblue](https://github.com/smellsblue))

## 1.0.0 (2015-12-25)

  There are no changes since the last release.

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
