require_relative "includes"
require_relative "../../logging"
require_relative "../../profile_configuration"
require_relative "abstract_factory"
require_relative "environment"
require_relative "repository"
require_relative "instance_profile"
require_relative "assume_role"
require_relative "shared_keyring"
require_relative "shared"
require_relative "static"

class AwsAssumeRole::Credentials::Factories::DefaultChainProvider
    extend Dry::Initializer::Mixin
    include AwsAssumeRole::Credentials::Factories

    option :access_key_id, Dry::Types["strict.string"].optional, default: proc { nil }
    option :credentials, default: proc { nil }
    option :secret_access_key, Dry::Types["strict.string"].optional, default: proc { nil }
    option :session_token, Dry::Types["strict.string"].optional, default: proc { nil }
    option :duration_seconds, Dry::Types["coercible.int"].optional, default: proc { nil }
    option :external_id, Dry::Types["strict.string"].optional, default: proc { nil }
    option :persist_session, Dry::Types["strict.bool"], default: proc { true }
    option :profile, Dry::Types["strict.string"].optional, default: proc { nil }
    option :profile_name, Dry::Types["strict.string"].optional, default: proc { @profile }
    option :region, Dry::Types["strict.string"].optional, default: proc { nil }
    option :role_arn, Dry::Types["strict.string"].optional, default: proc { nil }
    option :role_session_name, Dry::Types["strict.string"].optional, default: proc { nil }
    option :serial_number, Dry::Types["strict.string"].optional, default: proc { nil }
    option :use_mfa, default: proc { false }
    option :no_profile, default: proc { false }
    option :source_profile, Dry::Types["strict.string"].optional, default: proc { nil }
    option :instance_profile_credentials_retries, Dry::Types["strict.int"], default: proc { 0 }
    option :instance_profile_credentials_timeout, Dry::Types["coercible.float"], default: proc { 0.0001 }

    def initialize(*options)
        if options[0].is_a? Seahorse::Client::Configuration::DefaultResolver
            initialize_with_seahorse(options[0])
        else
            super(*options)
        end
        @profile_name ||= @profile
    end

    def resolve
        resolve_credentials(:credential_provider, true)
        return @credentials if @credentials && @credentials.set? && !use_mfa && !role_arn
        resolve_credentials(:second_factor_provider, true)
        return @credentials if @credentials && @credentials.set? && !role_arn
        resolve_credentials(:role_assumption_provider, true)
        return @credentials if @credentials.set?
        @credentials || Aws::Credentials.new(nil, nil, nil)
    end

    private

    def initialize_with_seahorse(resolver)
        keys = resolver.resolve
        options = keys.map do |k|
            [k, resolver.send(k)]
        end
        __initialize__(options.to_h)
    end

    def to_h
        instance_values.delete("__options__").symbolize_keys.merge(
            instance_profile_credentials_retries: instance_profile_credentials_retries,
            instance_profile_credentials_timeout: instance_profile_credentials_timeout,
        )
    end

    def resolve_credentials(type, break_if_successful = false)
        factories_to_try = Repository.factories[type]
        factories_to_try.each do |x|
            options = to_h
            options[:credentials] = credentials if credentials && credentials.set?
            creds = x.new(options).credentials
            next unless creds && creds.set?
            @credentials = creds
            break if break_if_successful
        end
    end
end

module AwsAssumeRole
    DefaultProvider = AwsAssumeRole::Credentials::Factories::DefaultChainProvider
end
