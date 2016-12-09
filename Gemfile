# frozen_string_literal: true
source 'https://rubygems.org'

gemspec

case Gem::Platform.local.os
when 'linux'
    gem 'gir_ffi-gnome_keyring', '~> 0.0.3'
when 'darwin'
    gem 'ruby-keychain', '~> 0.3.2'
end

# Development dependencies - didn't seem to get installed when
# referenced in the gemspec, find out why.
gem 'bundler'
gem 'rake'
gem 'rspec'
gem 'rubocop', require: false
