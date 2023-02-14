source 'https://rubygems.org'

gemspec

platforms :jruby do
  gem "activerecord-jdbc-adapter"
  gem "activerecord-jdbcsqlite3-adapter"
  gem "jruby-openssl"
end

platforms :ruby do
  gem "sqlite3"
end

platform :mri do
  # gem "ruby-prof", "~> 0.11.2"

  case RUBY_VERSION
  when /^1.9/
    gem 'debugger'
  end
end

group :development do
  gem "pry"
  gem 'rb-inotify', '~> 0.9'
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-rails'
end

case ENV['TEST_RAILS_VERSION']
when "6.0"
  gem "activesupport", "~> 6.0.4"
when "6.1"
  gem "activesupport", "~> 6.1.4"
when "7.0"
  gem "activesupport", "~> 7.0.4"
end
