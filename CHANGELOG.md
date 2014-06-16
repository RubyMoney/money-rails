# Changelog

## master (next release)
- Raise error when trying to change model based currency
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

