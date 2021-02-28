# Changelog

## 1.14.0

- Tweaks to support Ruby 3.0

## 1.13.4

- Fix validator race condition
- Add Danish translation for errors
- Change Money fields to Decimal in Rails Admin
- Run hooks after active_record.initialize_database
- Add optional currency argument to "#currency_symbol" helper
- Rails 6.1 support

## 1.13.3

- Add Money#to_hash for JSON serialization
- Update initializer template with #locale_backend config
- Rollback support for remove_monetize / remove_money DB helpers
- Rails 6 support

## 1.13.2

- Make validation compatible with Money.locale_backend

## 1.13.1

- Add a guard clause for "blank form" input (Mongoid)
- Do not add extra errors in case attribute is not a number
- Use Money.locale_backend instead of Money.use_i18n
- Add money_only_cents helper method

## 1.13.0

- Bump money version to ~> 6.13.0

## 1.12.0

- Bump money version to ~> 6.12.0
- Bump monetize version to ~> 1.9.0

## 1.11.0

- Bump money version to ~> 6.11.0
- Add test helper for with_model_currency
- Fix empty validation errors from being assigned

## 1.10.0

- Bump money version to ~> 6.10.0
- Optimize reading of the attribute when `allow_nil` is set to true

## 1.9.0

- Allow the use of money-rails with plan ActiveRecord (without Rails)
- Remove translation of postfix for the amount column (always use _cents by default)
- Push Monetize dependency from 1.6.0 to 1.7.0

## 1.8.0

- Ruby 2.4 support
- Upgrade Money dependency from 6.7 to 6.8.1
- Upgrade Monetize dependency from 1.4.0 to 1.6.0
- Raise `MoneyRails::Error` instead of exposing Money and Monetize errors

## 1.7.0

- Rails 5 support
- Mongoid 5 support
- Do not convert Mongoid money fields from nil to zero
- Refactor `#monetize` method

## 1.6.2

- Fix attribute order possibly affecting the value of monetized attribute
- Add support for RailsAdmin (use :money type)
- Raise error when gem was unable to infer monetized attribute name
- Revert decimal mark and thousands separator addtion, since formatting should depend on country and locale, instead of currency

## 1.6.1

- View helper now respects currency decimal mark and thousands separator
- Fix error when monetizing with attribute's name
- Fix mime-types dependency issue with ruby 1.9
- Fix issue with gem not updating automatically inferred currency column

## 1.6.0

- Update Money and Monetize gem reqs.

## 1.5.0

- Respect Money.use_i18n when validating.
- Include attribute in validation messages like Rails does.
- Respect `raise_error_on_money_parsing` before raising a MoneyRails::ActiveRecord::Monetizable::ReadOnlyCurrencyException.

## 1.4.1

 - validator was looking for monetizable_attributes using a symbol key, when the keys are all strings. Asserted string key values in rspec and changed validator to look for a string key.
 - make monetized_attribute hash comparison order independent
 - Isolate class used for the monetized_attributes tests to prevent cross-contamination
 - rename `format_with_settings` method to `format`
 - add gem tasks

## 1.4.0

- Fix validation failing when both superclass and subclass use monetize macros and any of them validates any field
- Extract db adapter without open connection on load
- Add support for field currency values to be determined by lambda.
- Simplify validation options
- Test for skipping validations separately from each other
- Instead of requiring either the PG version or the non, always require the PG version and only fail to require the non when using PG, that way monetize will always work and money is supported for backwards compat. This way you can have a system with sqlite for dev and pg for production, for instance, and things still work.
- Refactor monetized_attributes
- updating db/schema.rb
- DRYing migration extensions
- Testing against latest ruby version
- Include postgres specific code also when adaptor = postgis.
- chore(add read only exception class)
- tiny schema change

## 1.3.0

- Use currency_column[:postfix] to automatically determine currency column.
- Replacing getter method with attr_reader.
- Support the `disambiguate` option on humanized_money helper.
- Restore mongoid functionality on Rails < 4.0.
- Support multiple attributes w/ one call to `monetize` for AR.
- Add `add_monetize` and `remove_monetize` migration helpers, to fix a naming
  clash introduced by the Rails 4.2 Postgres adapter Use correct amount for
  validator when subunit is set directly.
- Fix store_accessor compatibility.
- Use `public_send` instead of `send` throughout the `monetize` method.

## 1.2.0

- Fixing tests which were broken on Rails 4.2.
- Add Rails 4.2 spec and update money dependency to 6.5.0.

## 1.1.0

- Update dependencies to money 6.4.x and monetize 1.0.x.
- Make subunit setter (e.g. `#price_cents=`) set the `before_type_cast...` va
  riable. (Fixes validation errors.)
- use HashWithIndifferentAccess instead of Hash for
  ActiveRecord::Base::monetized_attributes
- Let the 'monetize' test helper work when testing against the model's class,
  as well as an instance of that class.
- Remove additional underscore in postfix comment
- Rescue UnknownCurrency within ActiveRecord
- Upgrade specs to RSpec 3
- Use #respond_to? instead of #try? when monetizing an aliased attribute.
- Allow aliased attributes to be monetized
- Fix compatability issue with Rails 4.2
- Allow empty string as thousands separator.
- Allow using a lambda to set default_currency

## 1.0.0

- Refactoring MoneyRails::ActiveModel::MoneyValidator#validate_each
- Update dependencies to money 6.2.x and monetize 0.4.x.
- Rescue from unknown currency errors on mongoization
- Add specs for Mongoize with invalid currency
- Add dedicated gemfiles and specs for Mongoid 3 and 4
- Show actual value of Money object in validation error message

## 0.12.0
- Add allow_nil chain for monetize test helper
- Add testing tasks for rails 4.1

## 0.11.0
- Helpers respect no_cents_if_whole configuration option (GH-157)

## 0.10.0
- Depend on Money gem version ~> 6.1.1
- Depend on monetize gem version ~> 0.3.0
- Set mongoized value of cents to float
- Fix validation error with whitespace between currency symbol and amount
- Add raise_error_on_money_parsing configuration option (default is false)
- Add rounding mode configuration option (default is ROUND_HALF_UP)
- Rescue ArgumentError with invalid values in mongoid (GH-114)
- Compatiblity between ActiveModel::Validations and MoneyValidator
- Raise error when trying to change model based currency

## 0.9.0
- Depend on Money gem version ~> 6.0.0
- Add disable_validation option for skipping validations on monetized attributes
- Remove implicit usage of 'currency' as a default currency column
- Options to humanized_money_with_symbol are passed to humanized_money
- Fix mongoization of Money when using infinite_precision
- Add testing tasks for rails 4.x
- Fix issue with Numeric values in MoneyValidator (GH-83).
- Fix test helper
- Fix issue with money validator (GH-102).
- Change validation logic. Support Subunit and Money field
  validation with NumericalityValidator options.
  Moreover, now Money objects are normalized and pass through
  all validation steps.
- Add support for the global configuration of the sign_before_setting formatting option.

## 0.8.1
- Remove unnecessary files from gem build.
- Add options to ActionView helpers that enable the usage of any of the rules ::Money.format allows.
- Fix "setting amount_column for default_currency" to only accept
  postfix for default_currency with subunit.
- Add mongoid 4 support.

## 0.8.0 (yanked)
- Added defaults for amount and currency columns in database schema, based on the default currency.
- Use a better default subunit_unit name (choose the value of column.postfix set in the config).
- Began support of Rails 4.
- Added global settings for money object formatted output (:no_cents_if_whole, :symbol options).
- Enhanced money validator.
- Added ability to use numericality validations on monetize (GH-70).
- Fixed error caused by ActiveSupport::HashWithIndifferentAccess
  (GH-62).
- Added money-rails test helper (rspec matcher).

## 0.7.1
- Fix error when instantiating new model in mongoid extension (GH-60)

## 0.7.0
- Added custom validator for Money fields (GH-36)
- Added mongodb service test support for travis CI
- Fixed issue with current value assignment in text_field tags (GH-37)
- Fixed concatination of subunit_name and name (to be just a joins) to
  prevent an infinite loop
- From now on MoneyRails is an Engine (not only a Railtie)!
  This means it can use all the extra stuff such as localized files,
  attached models etc.
- Updated Money dependency version (Now we depend on 5.1.x)
- Allow immediate subclasses to inherit monetized_attributes
- Stopped support for MRI < 1.9.2
- Fixed issue related to symbolized keys in Mongoid (GH-40)
- Added add_money/remove_money & t.money/t.remove_money methods for ActiveRecord migrations

## 0.6.0
- Added basic support for Mongoid >= 3.0.
- Allow class methods to be monetized (ActiveRecord only - GH-34)

## 0.5.0

- Refactored instance currency implementation. Now, instance currency
  is permitted to override the field currency, if they are both non-nil
  values. (GH-23)
- Replaced deprecated composed_of with a custom implementation for
  activerecord. (GH-20)
- Refactored testing structure to support multiple ORMs/ODMS.
- Added Mongoid 2.x basic support. It uses serialization
  (a differrent approach than activerecord for now). (GH-19)

## 0.4.0

- Provide ActionView helpers integration.
- Map blank value assignments (for monetized fields) to nil.
- Allow nil values for monetized fields. (GH-15)
- Reworked support for ORM adaptation. (GH-16)

## 0.3.1

- Fix bug with string assignment to monetized field. (GH-11)

## 0.3.0

- Add support for model-wise currency.
- Fix conversion of monetized attribute value, whether a currency
  table column exists or not.
- Add configuration options for currency exchange (config.add_rate,
  config.default_bank)

## 0.2.0

- Add new generator to install money.rb initializer
- Create a structure to enable better ORM/ODM integration
- Add configuration for numericality validation of monetized fields
- Add support for custom currency registration

## 0.1.0

- Use better names for args :target_name, :field_currency,
  :model_currency. From now on, :as, :with_currency and :with_model_currency should
  be used instead of the old ones which are deprecated. (GH-6)

## 0.0.1

- Hello World

