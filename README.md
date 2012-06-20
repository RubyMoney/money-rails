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

### Currencies

Money-rails supports a set of options to handle currencies for your
monetized fields. The default option for every conversion is to use
the global default currency of Money library, as given in the configuration
initializer of money-rails:

```ruby
# config/initializers/money.rb
MoneyRails.configure do |config|

  # set the default currency
  config.default_currency = :usd

end
```

In many cases this is not enough, so there are some other options to
satisfy your needs.

#### Model Currency

You can define a specific currency for an activerecord model. This currency is
used for the creation and conversions of the Money objects referring to
every monetized attributes of the specific model. This means it overrides
the global default currency of Money library. To attach a currency to a
model use the ```register_currency``` macro:

```ruby
# app/models/product.rb
class Product < ActiveRecord::Base

  # Use EUR as model level currency
  register_currency :eur

  monetize :discount_subunit, :as => "discount"
  monetize :bonus_cents

end
```

Now ```product.discount``` and ```product.bonus``` will return a Money
object using EUR as currency, instead of the default USD.

#### Attribute Currency (:with_currency)

By using the key ```:with_currency``` with a currency symbol value in
the ```monetize``` macro call, you can define a currency in a more
granular way. This way you attach a currency only to the specific monetized
model attribute. It also allows to override both the model level
and the global default currency:

```ruby
# app/models/product.rb
class Product < ActiveRecord::Base

  # Use EUR as model level currency
  register_currency :eur

  monetize :discount_subunit, :as => "discount"
  monetize :bonus_cents, :with_currency => :gbp

end
```

In this case the ```product.bonus``` will return a Money object of GBP
currency, whereas ```product.discount.currency_as_string # => EUR ```

#### Instance Currencies

All the previous options do not require any extra model field to hold
currency values. If you need to provide differrent currency per model
instance, then you need to add a column with the name ```currency```
in your db table. Money-rails will discover this automatically,
and will use this knowledge to override the model level and global
default values. Attribute currency cannot be combined with instance
currency!

```ruby
class Transaction < ActiveRecord::Base

  # This model has a separate currency column
  attr_accessible :amount_cents, :currency, :tax_cents

  # Use model level currency
  register_currency :gbp

  monetize :amount_cents
  monetize :tax_cents

end

# Now instantiating with a specific currency overrides the
# the model and global currencies
t = Transaction.new(:amount_cents => 2500, :currency => "CAD")
t.amount == Money.new(2500, "CAD") # true
```

WARNING: In this case :with_currency is not permitted and the usage
of this parameter will cause an ArgumentError exception.

In general, the use of this strategy is discouraged unless there is a reason.

### Configuration parameters

You can handle a bunch of configuration params through ```money.rb``` initializer:

```
MoneyRails.configure do |config|

  # To set the default currency
  #
  config.default_currency = :usd

  # Add custom exchange rates
  config.add_rate "USD", "CAD", 1.24515
  config.add_rate "CAD", "USD", 0.803115

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

* ```default_currecy```: Set the default (application wide) currency (USD is the default)
* ```include_validations```: Permit the inclusion of a ```validates_numericality_of```
  validation for each monetized field (the default is true)
* ```register_currency```: Register one custom currency. This option can be
  used more than once to set more custom currencies. The value should be
  a hash of all the necessary key/value pairs (important keys: ```:priority```, ```:iso_code```,
  ```:name```, ```:symbol```, ```:symbol_first```, ```:subunit```, ```:subunit_to_unit```,
  ```:thousands_separator```, ```:decimal_mark```).
* ```add_rate```: Provide custom exchange rate for currencies in one direction
  only! This rate is added to the attached bank object.
* ```default_bank```: The default bank object holding exchange rates etc.
  (https://github.com/RubyMoney/money#currency-exchange)

## Maintainers

* Andreas Loupasakis (https://github.com/alup)
* Shane Emmons (https://github.com/semmons99)
* Simone Carletti (https://github.com/weppos)

## License

MIT License. Copyright 2012 RubyMoney.
