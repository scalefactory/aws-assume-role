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

class AwsAssumeRole::Credentials::Factories::DefaultChainProvider < Dry::Struct
    constructor_type :schema
    include AwsAssumeRole::Credentials::Factories
    include AwsAssumeRole::Logging

    attribute :access_key_id, Dry::Types["strict.string"].optional
    attribute :credentials, Dry::Types["object"].optional
    attribute :secret_access_key, Dry::Types["strict.string"].optional
    attribute :session_token, Dry::Types["strict.string"].optional
    attribute :duration_seconds, Dry::Types["coercible.int"].optional
    attribute :external_id, Dry::Types["strict.string"].optional
    attribute :persist_session, Dry::Types["strict.bool"].default(true)
    attribute :profile, Dry::Types["strict.string"].optional
    attribute :profile_name, Dry::Types["strict.string"].optional
    attribute :region, Dry::Types["strict.string"].optional
    attribute :role_arn, Dry::Types["strict.string"].optional
    attribute :role_session_name, Dry::Types["strict.string"].optional
    attribute :serial_number, Dry::Types["strict.string"].optional
    attribute :use_mfa, Dry::Types["strict.bool"].default(false)
    attribute :no_profile, Dry::Types["strict.bool"].default(false)
    attribute :source_profile, Dry::Types["strict.string"].optional
    attribute :instance_profile_credentials_retries, Dry::Types["strict.int"].default(0)
    attribute :instance_profile_credentials_timeout, Dry::Types["coercible.float"].default(1.0)

    def initialize(*options)
        logger.debug "DefaultChainProvider started"
        if options[0].is_a? Seahorse::Client::Configuration::DefaultResolver
            initialize_with_seahorse(options[0])
        else
            super(*options)
        end
        @profile_name ||= @profile
        @original_profile = @profile
    end

    def resolve(nil_with_role_not_set: false, explicit_default_profile: false)
        resolve_final_credentials(explicit_default_profile)
        nil_creds = Aws::Credentials.new(nil, nil, nil)
        return nil_creds if (nil_with_role_not_set &&
                             @role_arn &&
                             @credentials.credentials.session_token.nil?) || @credentials.nil?
        @credentials
    end

    private

    def resolve_final_credentials(explicit_default_profile = false)
        resolve_credentials(:credential_provider, true, explicit_default_profile)
        return @credentials if @credentials && @credentials.set? && !use_mfa && !role_arn
        resolve_credentials(:second_factor_provider, true, explicit_default_profile)
        return @credentials if @credentials && @credentials.set? && !role_arn
        resolve_credentials(:role_assumption_provider, true, explicit_default_profile)
        return @credentials if @credentials && @credentials.set?
        Aws::Credentials.new(nil, nil, nil)
    end

    def initialize_with_seahorse(resolver)
        keys = resolver.resolve
        options = keys.map do |k|
            [k, resolver.send(k)]
        end
        __initialize__(options.to_h)
    end

    def to_h
        to_hash
    end

    def resolve_credentials(type, break_if_successful = false, explicit_default_profile = false)
        factories_to_try = Repository.factories[type]
        factories_to_try.each do |x|
            options = to_h
            options[:credentials] = credentials if credentials && credentials.set?
            factory = x.new(options)
            @region ||= factory.region
            @profile ||= factory.profile
            @role_arn ||= factory.role_arn
            next unless factory.credentials && factory.credentials.set?
            next if explicit_default_profile && (@profile == "default") && (@profile != @original_profile)
            @credentials ||= factory.credentials
            break if break_if_successful
        end
    end
end

module AwsAssumeRole
    DefaultProvider = AwsAssumeRole::Credentials::Factories::DefaultChainProvider
end
