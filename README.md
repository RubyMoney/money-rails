# RubyMoney - Money-Rails [![endorse](http://api.coderwall.com/alup/endorsecount.png)](http://coderwall.com/alup)

[![Build Status](https://secure.travis-ci.org/RubyMoney/money-rails.png?branch=master)](http://travis-ci.org/RubyMoney/money-rails)
[![Dependency Status](https://gemnasium.com/RubyMoney/money-rails.png)](https://gemnasium.com/RubyMoney/money-rails)
[![Code Climate](https://codeclimate.com/github/RubyMoney/money-rails.png)](https://codeclimate.com/github/RubyMoney/money-rails)

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

### Setup for money-rails development

Our tests are executed with several ORMs - see `Rakefile` for details. To install all required gems run these:

    bundle install --gemfile=gemfiles/mongoid2.gemfile
    bundle install --gemfile=gemfiles/mongoid3.gemfile
    bundle install --gemfile=gemfiles/rails3.gemfile
    bundle install --gemfile=gemfiles/rails4.gemfile

Then you can run the test suite with `rake`,

## Usage

### ActiveRecord

#### Usage example

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

#### Migration helpers

If you want to add money field to product model you may use ```add_money``` helper. That
helper might be customized inside ```MoneyRails.configure``` block. You should customize
```add_money``` helper to match the most common use case and utilize it across all migrations.

```ruby
class MonetizeProduct < ActiveRecord::Migration
  def change
    add_money :products, :price

    # OR

    change_table :products do |t|
      t.money :price
    end
  end
end
```

Another example where the currency column is not including:

```ruby
class MonetizeItem < ActiveRecord::Migration
  def change
    add_money :items, :price, currency: { present: false }
  end
end
```

```add_money``` helper is revertable, so you may use it inside ```change``` migrations.
If you writing separate ```up``` and ```down``` methods, you may use ```remove_money``` helper.

#### Allow nil values

If you want to allow the assignment of nil and/or blank values to a specific
monetized field, you can use the `:allow_nil` parameter like this:

```
# in Product model
monetize :optional_price_cents, :allow_nil => true

# in Migration
def change
  add_money :products, :optional_price, amount: { null: true, default: nil }
end

# then blank assignments are permitted
product.optional_price = nil
product.save # returns without errors
product.optional_price # => nil
product.optional_price_cents # => nil
```

#### Numericality validation options

You can also pass along
[numericality validation options](http://guides.rubyonrails.org/active_record_validations.html#numericality)
such as this:

```ruby
monetize :price_in_a_range_cents, :allow_nil => true,
  :numericality => {
    :greater_than_or_equal_to => 0,
    :less_than_or_equal_to => 10000
  }
```

### Mongoid 2.x and 3.x

`Money` is available as a field type to supply during a field definition:

```ruby
class Product
  include Mongoid::Document

  field :price, type: Money
end

obj = Product.new
# => #<Product _id: 4fe865699671383656000001, _type: nil, price: nil>

obj.price
# => nil

obj.price = Money.new(100, 'EUR')
# => #<Money cents:100 currency:EUR>

obj.price
#=> #<Money cents:100 currency:EUR>

obj.save
# => true

obj
# => #<Product _id: 4fe865699671383656000001, _type: nil, price: {:cents=>100, :currency_iso=>"EUR"}>

obj.price
#=> #<Money cents:100 currency:EUR>

## You can access the money hash too :
obj[:price]
# => {:cents=>100, :currency_iso=>"EUR"}
```

The usual options on `field` as `index`, `default`, ..., are available.

### Method conversion

Method return values can be converted in the same way attributes are converted. For example:

```ruby
class Transaction < ActiveRecord::Base

  monetize :price_cents
  monetize :tax_cents
  monetize :total_cents
  def total_cents
    return price_cents + tax_cents
  end

end
```

Now each Transaction object has a method called `total` which returns a Money object.

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

You can define a specific currency for an activerecord model (not for mongoid).
This currency is used for the creation and conversions of the Money objects
referring to every monetized attributes of the specific model.
This means it overrides the global default currency of Money library.
To attach a currency to a model use the ```register_currency``` macro:

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
default values. Non-nil instance currency values also override attribute
currency values, so they have the highest precedence.

```ruby
class Transaction < ActiveRecord::Base

  # This model has a separate currency column
  attr_accessible :amount_cents, :currency, :tax_cents

  # Use model level currency
  register_currency :gbp

  monetize :amount_cents
  monetize :tax_cents

end

# Now instantiating with a specific currency overrides
# the model and global currencies
t = Transaction.new(:amount_cents => 2500, :currency => "CAD")
t.amount == Money.new(2500, "CAD") # true
```

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

  # Default ActiveRecord migration configuration values for columns:
  #
  # config.amount_column = { prefix: '',           # column name prefix
  #                          postfix: '_cents',    # column name  postfix
  #                          column_name: nil,     # full column name (overrides prefix, postfix and accessor name)
  #                          type: :integer,       # column type
  #                          present: true,        # column will be created
  #                          null: false,          # other options will be treated as column options
  #                          default: 0
  #                        }
  #
  # config.currency_column = { prefix: '',
  #                            postfix: '_currency',
  #                            column_name: nil,
  #                            type: :string,
  #                            present: true,
  #                            null: false,
  #                            default: 'USD'
  #                          }

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

  # Set money formatted output globally.
  # Default value is nil meaning "ignore this option".
  # Options are nil, true, false.
  #
  # config.no_cents_if_whole = nil
  # config.symbol = nil
  # config.sign_before_symbol = nil
end
```

* ```default_currency```: Set the default (application wide) currency (USD is the default)
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
* ```no_cents_if_whole```: Force `Money#format` method to use its value as the default for ```no_cents_if_whole``` key.
* ```symbol```: Use its value as the default for ```symbol``` key in
  `Money#format` method.
* ```sign_before_symbol```: Force `Money#format` to place the negative sign before the currency symbol.
* ```amount_column```: Provide values for the amount column (holding the fractional part of a money object).
* ```currency_column```: Provide default values or even disable (`present: false`) the currency column.

### Helpers

* the `currency_symbol` helper method

```
<%= currency_symbol %>
```
This will render a `span` dom element with the default currency symbol.

* the `humanized_money` helper method

```
<%= humanized_money @money_object %>
```
This will render a formatted money value without the currency symbol and
without the cents part if it contains only zeros (uses
`:no_cents_if_whole flag`).

* humanize with symbol helper

```
<%= humanized_money_with_symbol @money_object %>
```
This will render a formatted money value including the currency symbol and
without the cents part if it contains only zeros.

* get the money value without the cents part

```
<%= money_without_cents @money_object %>
```
This will render a formatted money value without the currency symbol and
without the cents part.

* get the money value without the cents part and including the currency
  symbol

```
<%= money_without_cents_and_with_symbol @money_object %>
```
This will render a formatted money value including the currency symbol and
without the cents part.

### Testing

If you use Rspec there is an test helper implementation.
Just write `require "money-rails/test_helpers"` in spec_helper.rb and
`include MoneyRails::TestHelpers` inside a describe block you want to
use the helper.

* the `monetize` matcher

```
monetize(:price_cents).should be_true
```
This will ensure that a column called `price_cents` is being monetized.

```
monetize(:price_cents).as(:discount_value).should be_true
```
By using `as` chain you can specify the exact name to which a monetized
column is being mapped.

```
monetize(:price_cents).with_currency(:gbp).should be_true
```

By using the `with_currency` chain you can specify the expected currency
for the chosen money attribute. (You can also combine all the chains.)

For examples on using the test_helpers look at
[test_helpers_spec.rb](https://github.com/RubyMoney/money-rails/blob/master/spec/test_helpers_spec.rb)

## Supported ORMs/ODMs

* ActiveRecord (>= 3.x)
* Mongoid (2.x, 3.x)

## Supported Ruby interpreters

* MRI Ruby >= 1.9.2

You can see a full list of the currently supported interpreters in [travis.yml](http://github.com/RubyMoney/money-rails/blob/master/.travis.yml)

## Maintainers

* Andreas Loupasakis (https://github.com/alup)
* Shane Emmons (https://github.com/semmons99)
* Simone Carletti (https://github.com/weppos)

## License

MIT License. Copyright 2012-2013 RubyMoney.
