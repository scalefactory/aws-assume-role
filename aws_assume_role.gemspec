# frozen_string_literal: true

$LOAD_PATH << File.expand_path("../lib", __FILE__)
require "aws_assume_role/version"

PLATFORM = ENV.fetch("PLATFORM", Gem::Platform.local.os)

Gem::Specification.new do |spec|
    spec.name    = "aws_assume_role"
    spec.version = AwsAssumeRole::VERSION
    spec.authors = [
        "Jon Topper",
        "Jack Thomas",
        "Naadir Jeewa",
        "David King",
        "Tim Bannister",
        "Phil Potter",
        "Tom Haynes",
        "Alan Ivey",
        "David O'Rourke",
    ]
    spec.email = [
        "jon@scalefactory.com",
        "jack@scalefactory.com",
        "naadir@scalefactory.com",
        "tim@scalefactory.com",
        "david@scalefactory.com",
    ]

    spec.description   = "Used to fetch multiple AWS Role Credential "\
                         "Keys using different Session Keys "\
                         "and store them securely using Gnome Keyring "\
                         "or OSX keychain"
    spec.summary       = "Manage AWS STS credentials with MFA"
    spec.homepage      = "https://github.com/scalefactory/aws-assume-role"
    spec.license       = "Apache-2.0"

    spec.files         = `git ls-files -z`.split("\x0").reject { |f|
        f.match(%r{^(test|spec|features)/})
    }
    spec.bindir        = "bin"
    spec.executables   = spec.files.grep(%r{^bin/aws}) { |f| File.basename(f) }
    spec.require_paths = ["lib"]
    spec.platform = PLATFORM unless ENV.fetch("GENERIC_GEM", false)
    spec.add_runtime_dependency "activesupport", "~> 4.2"
    spec.add_runtime_dependency "aws-sdk", "~> 2.7"
    spec.add_runtime_dependency "dry-configurable", "~> 0.5"
    spec.add_runtime_dependency "dry-struct", "~> 0.5"
    spec.add_runtime_dependency "dry-types", "~> 0.13", "< 0.15"
    spec.add_runtime_dependency "dry-validation", "~> 0.11"
    spec.add_runtime_dependency "gli", "~> 2.15"
    spec.add_runtime_dependency "highline", "~> 1.6"
    spec.add_runtime_dependency "i18n", "~> 0.7"
    spec.add_runtime_dependency "inifile", "~> 3.0"
    spec.add_runtime_dependency "launchy", "~> 2.4"
    spec.add_runtime_dependency "keyring", "~> 0.4", ">= 0.4.1"
    spec.add_runtime_dependency "pastel", "~> 0.7"
    spec.add_runtime_dependency "smartcard", "~> 0.5.6"
    spec.add_runtime_dependency "yubioath", "~> 1.2", ">= 1.2.1"
    spec.add_development_dependency "rspec", "~> 3.5"
    spec.add_development_dependency "rubocop", "0.50"
    spec.add_development_dependency "yard", "~> 0.9"
    spec.add_development_dependency "simplecov", "~> 0.13"
    spec.add_development_dependency "webmock", "~> 2.3"

    case PLATFORM
    when /linux|bsd/
        spec.add_dependency "gir_ffi-gnome_keyring", "~> 0.0", ">= 0.0.9"
    when /darwin/
        spec.add_dependency "ruby-keychain", "~> 0.3", ">= 0.3.2"
    end
end
