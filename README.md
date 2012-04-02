# RubyMoney - Money-Rails


## Introduction

This library provides integration of [money](http://github.com/Rubymoney/money) gem with Rails.

Use 'monetize' to specify which fields you want to be backed by
Money objects and helpers provided by the [money](http://github.com/Rubymoney/money)
gem.

## Installation

Add this line to your application's Gemfile:

    gem 'money-rails'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install money-rails


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
```_cents``` suffix of the column name. If you prefer another name for the
money attribute, then you can provide ```target_name``` argument with a string
value to the ```monetize``` macro:

```ruby
monetize :discount, :target_name => "discount_value"
```

Now the model objects will have a ```discount_value``` attribute which
is a Money object, wrapping the value of ```discount``` column to a
Money instance.


## License

MIT License. Copyright 2012 RubyMoney.