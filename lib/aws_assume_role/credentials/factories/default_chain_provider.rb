# frozen_string_literal: true

require_relative "includes"
require_relative "../../logging"
require_relative "../../profile_configuration"
require_relative "abstract_factory"
require_relative "environment"
require_relative "repository"
require_relative "instance_profile"
require_relative "assume_role"
require_relative "shared"
require_relative "static"

class AwsAssumeRole::Credentials::Factories::DefaultChainProvider < Dry::Struct
    constructor_type :schema
    include AwsAssumeRole::Credentials::Factories
    include AwsAssumeRole::Logging

    attribute :access_key_id, Dry::Types["strict.string"].optional
    attribute :credentials, Dry::Types["object"].optional
    attribute :duration_seconds, Dry::Types["coercible.int"].optional
    attribute :external_id, Dry::Types["strict.string"].optional
    attribute :instance_profile_credentials_retries, Dry::Types["strict.int"].default(0)
    attribute :instance_profile_credentials_timeout, Dry::Types["coercible.float"].default(1.0)
    attribute :mfa_serial, Dry::Types["strict.string"].optional
    attribute :no_profile, Dry::Types["strict.bool"].default(false)
    attribute :path, Dry::Types["strict.string"].optional
    attribute :persist_session, Dry::Types["strict.bool"].default(true)
    attribute :profile_name, Dry::Types["strict.string"].optional
    attribute :profile, Dry::Types["strict.string"].optional
    attribute :region, Dry::Types["strict.string"].optional
    attribute :role_arn, Dry::Types["strict.string"].optional
    attribute :role_session_name, Dry::Types["strict.string"].optional
    attribute :secret_access_key, Dry::Types["strict.string"].optional
    attribute :serial_number, Dry::Types["strict.string"].optional
    attribute :session_token, Dry::Types["strict.string"].optional
    attribute :source_profile, Dry::Types["strict.string"].optional
    attribute :use_mfa, Dry::Types["strict.bool"].default(false)
    attribute :yubikey_oath_name, Dry::Types["strict.string"].optional

    def self.new(options)
        if options.respond_to? :resolve
            finalize_instance new_with_seahorse(options)
        else
            finalize_instance(options)
        end
    end

    def self.finalize_instance(options)
        new_opts = options.to_h
        new_opts[:profile_name] ||= new_opts[:profile]
        new_opts[:original_profile] = new_opts[:profile_name]
        instance = allocate
        instance.send(:initialize, new_opts)
        instance
    end

    def self.new_with_seahorse(resolver)
        keys = resolver.resolve
        options = keys.map do |k|
            [k, resolver.send(k)]
        end
        finalize_instance(options.to_h)
    end

    def resolve(nil_with_role_not_set: false, explicit_default_profile: false)
        resolve_final_credentials(explicit_default_profile)
        # nil_creds = Aws::Credentials.new(nil, nil, nil)
        return nil if (nil_with_role_not_set &&
                             @role_arn &&
                             @credentials.credentials.session_token.nil?) || @credentials.nil?
        @credentials
    end

    def to_h
        to_hash
    end

    private

    def resolve_final_credentials(explicit_default_profile = false)
        resolve_credentials(:credential_provider, true, explicit_default_profile)
        return @credentials if @credentials&.set? && !use_mfa && !role_arn
        resolve_credentials(:second_factor_provider, true, explicit_default_profile)
        return @credentials if @credentials&.set?
        resolve_credentials(:instance_role_provider, true, explicit_default_profile)
        return @credentials if @credentials&.set?
        nil
    end

    def resolve_credentials(type, break_if_successful = false, explicit_default_profile = false)
        factories_to_try = Repository.factories[type]
        factories_to_try.each do |x|
            options = to_h
            options[:credentials] = credentials if credentials&.set?
            logger.debug "About to try credential lookup with #{x}"
            factory = x.new(options)
            @region ||= factory.region
            @profile ||= factory.profile
            @role_arn ||= factory.role_arn
            next unless factory.credentials&.set?
            logger.debug "Profile currently #{@profile}"
            next if explicit_default_profile && (@profile == "default") && (@profile != @original_profile)
            @credentials ||= factory.credentials
            logger.debug "Got #{@credentials}"
            break if break_if_successful
        end
    end
end

module AwsAssumeRole
    DefaultProvider = AwsAssumeRole::Credentials::Factories::DefaultChainProvider
end
