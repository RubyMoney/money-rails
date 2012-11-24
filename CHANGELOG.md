# Changelog

## 0.7.0 (coming soon)
- Added custom validator for Money fields (GH-36)
  TODO: decouple validator from active_record
- Added mongodb service test support for travis CI
- Fixed issue with current value assignment in text_field tags (GH-37)
- Fixed issue related to symbolized keys in Mongoid (GH-40)
- Added monetize/demonetize methods for ActiveRecord migrations

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

