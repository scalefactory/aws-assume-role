require_relative "includes"

module AwsAssumeRole
    class Configuration
        extend Dry::Configurable
        Types = Dry::Types.module

        setting(:backend_plugin, ENV.fetch("AWS_ASSUME_ROLE_KEYRING_PLUGIN", nil)) do |value|
            Types::Coercible::String[value]
        end

        setting(:backend, ENV.fetch("AWS_ASSUME_ROLE_KEYRING_BACKEND", "automatic")) do |value|
            value == "automatic" ? nil : Types::Coercible::String[value]
        end

        setting(:log_level, ENV.fetch("AWS_ASSUME_ROLE_LOG_LEVEL", "WARN"))
    end
    Config = Configuration.config
end
