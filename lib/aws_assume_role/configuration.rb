# frozen_string_literal: true

require_relative "includes"

module AwsAssumeRole
    class Configuration
        extend Dry::Configurable
        Types = Dry.Types(default: :nominal)

        setting(:backend_plugin, ENV.fetch("AWS_ASSUME_ROLE_KEYRING_PLUGIN", nil)) do |value|
            Types::Coercible::String[value]
        end

        setting(:backend, ENV.fetch("AWS_ASSUME_ROLE_KEYRING_BACKEND", "automatic")) do |value|
            value == "automatic" ? nil : Types::Coercible::String[value]
        end

        setting(:log_level, ENV.fetch("AWS_ASSUME_ROLE_LOG_LEVEL", "WARN")) do |value|
            {
                DEBUG: 0,
                INFO: 1,
                WARN: 2,
                ERROR: 3,
                FATAL: 4,
                UNKNOWN: 5,
            }[value.to_sym] || 2
        end
    end
    Config = Configuration.config
end
