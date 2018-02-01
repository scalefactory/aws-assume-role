## 1.1.1
* Allow aws-assume-role to retrieve all Yubikey stored OATH tokens (@alanthing)

## 1.1.0
* Publish separate gems for Linux, BSD and MacOS (@randomvariable)

## 1.0.6
* Determine gem dependencies for OS X & Linux at install time (@randomvariable)

## 1.0.5
* Escape run commands properly (@mrprimate)

## 1.0.4
* Ensure ~/.aws exists before saving configuration

## 1.0.3
* Fix setting environment variable throwing string frozen error (@timbirk)

## 1.0.2
* Display credential prompts on stderr to allow shell eval to work (@timbirk)

## 1.0.1
* Fix setting environment variable throwing string frozen error (@mrprimate)
* Fix incompatibility with version 0.4 of dry-struct (@tomhaynes)

## 1.0.0
* Fix deprecation warnings for dry-types
* Minimum Ruby version is now 2.2

## 0.2.2
* Add Yubikey OATH support to the default chain provider (@randomvariable)

## 0.2.1
* Loosen requirement on highline to improve compatibility with Puppet tools (@randomvariable)

## 0.2.0

* Add support for Yubikey as a source for MFA (@davbo)
* Remove expired credentials before writing new STS credentials (@davbo)

## 0.1.2

* Become compatible with Ruby 2.1 (@randomvariable)
* Added test suite from AWS SDK for Ruby (@randomvariable)

## 0.1.1

* Fix logging on Ruby 2.2 (@randomvariable)

## 0.1.0

* Complete rewrite with SDK compatible API layer (@randomvariable)

## 0.0.3

* Store master credentials in OS credential store. (@mrprimate)

## 0.0.2

* Add CLI (@mrprimate)

## 0.0.1

* Initial release (@jtopper)
