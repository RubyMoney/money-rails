# RubyMoney - Money-Rails

[![Build Status](https://secure.travis-ci.org/RubyMoney/money-rails.png?branch=master)](http://travis-ci.org/RubyMoney/money-rails)

## Introduction

This library provides integration of [money](http://github.com/Rubymoney/money) gem with Rails.

Use 'monetize' to specify which fields you want to be backed by
Money objects and helpers provided by the [money](http://github.com/Rubymoney/money)
gem.

Currently, this library is in active development mode, so if you would
like to have a new feature feel free to open a new issue
[here](https://github.com/RubyMoney/money-rails/issues). You are also
welcome to contribute to the project.

## Installation

Add this line to your application's Gemfile:

    gem 'money-rails'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install money-rails

You may also install money configuration initializer:

```
$ rails g money_rails:initializer
```

There, you can define the default currency value and set other
configuration parameters for the rails app.

## Usage

For example, we create a Product model which has an integer price_cents column
and we want to handle it by using a Money object instead:

```ruby
class Product < ActiveRecord::Base
  
  monetize :price_cents
  
end
```

Now each Product object will also have an attribute called ```price``` which
is a Money object and can be used for money comparisons, conversions etc.

In this case the name of the money attribute is created automagically by removing the
```_cents``` suffix of the column name. 

If you are using another db column name or you prefer another name for the
money attribute, then you can provide ```as``` argument with a string
value to the ```monetize``` macro:

```ruby
monetize :discount_subunit, :as => "discount"
```

Now the model objects will have a ```discount``` attribute which
is a Money object, wrapping the value of ```discount_subunit``` column to a
Money instance.

### Field currencies

You can define a specific currency per monetized field:

```ruby
monetize :discount_subunit, :as => "discount", :with_currency => :eur
```

Now ```discount_subunit``` will give you a Money object using EUR as
currency.

### Configuration parameters

You can handle a bunch of configuration params through ```money.rb``` initializer:

```
MoneyRails.configure do |config|

  # To set the default currency
  #
  config.default_currency = :usd

  # To handle the inclusion of validations for monetized fields
  # The default value is true
  #
  config.include_validations = true

  # Register a custom currency
  #
  # config.register_currency = {
  #   :priority            => 1,
  #   :iso_code            => "EU4",
  #   :name                => "Euro with subunit of 4 digits",
  #   :symbol              => "€",
  #   :symbol_first        => true,
  #   :subunit             => "Subcent",
  #   :subunit_to_unit     => 10000,
  #   :thousands_separator => ".",
  #   :decimal_mark        => ","
  # }
end
```

* default_currecy: Set the default (application wide) currency (USD is the default)
* include_validations: Permit the inclusion of a ```validates_numericality_of```
  validation for each monetized field (the default is true)
* register_currency: Register one custom currency. This option can be
  used more than once to set more custom currencies. The value should be
  a hash of all the necessary key/value pairs (important keys: :priority, :iso_code, :name,
  :symbol, :symbol_first, :subunit, :subunit_to_unit, :thousands_separator, :decimal_mark).

## Maintainers

* Andreas Loupasakis (https://github.com/alup)
* Shane Emmons (https://github.com/semmons99)
* Simone Carletti (https://github.com/weppos)

## License

MIT License. Copyright 2012 RubyMoney.
