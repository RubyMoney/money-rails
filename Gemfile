source 'https://rubygems.org'

gemspec

gem "bigdecimal"
gem "mutex_m"
gem "benchmark"
gem "drb"

platforms :jruby do
  gem "activerecord-jdbc-adapter"
  gem "activerecord-jdbcsqlite3-adapter"
  gem "jruby-openssl"
end

platforms :ruby do
  gem "sqlite3", '~> 1.4'
end

group :development do
  gem "pry"
  gem "money", git: "https://github.com/RubyMoney/money.git"
end
