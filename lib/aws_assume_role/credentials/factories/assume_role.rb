# frozen_string_literal: true

require_relative "abstract_factory"
require_relative "../providers/assume_role_credentials"
require_relative "../providers/mfa_session_credentials"

class AwsAssumeRole::Credentials::Factories::AssumeRole < AwsAssumeRole::Credentials::Factories::AbstractFactory
    include AwsAssumeRole::Credentials::Factories
    type :credential_provider
    priority 20

    def initialize(options)
        logger.debug "AwsAssumeRole::Credentials::Factories::AssumeRole initiated with #{options}"
        return unless options[:profile] || options[:role_arn]
        if options[:profile]
            logger.debug "AwsAssumeRole: #{options[:profile]} found. Trying with profile"
            try_with_profile(options)
        else
            if options[:use_mfa]
                options[:credentials] = AwsAssumeRole::Credentials::Providers::MfaSessionCredentials.new(options).credentials
            end
            @credentials = AwsAssumeRole::Credentials::Providers::AssumeRoleCredentials.new(options)
        end
    end

    def try_with_profile(options)
        return unless AwsAssumeRole.shared_config.config_enabled?
        logger.debug "AwsAssumeRole: Shared Config enabled"
        @profile = options[:profile]
        @region = options[:region]
        @credentials = assume_role_with_profile(options)
        @region ||= AwsAssumeRole.shared_config.profile_region(@profile)
        @role_arn ||= AwsAssumeRole.shared_config.profile_role(@profile)
    end

    def assume_role_with_profile(options)
        AwsAssumeRole.shared_config.assume_role_credentials_from_config(options)
    end
end
