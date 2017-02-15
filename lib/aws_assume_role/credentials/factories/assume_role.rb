require_relative "abstract_factory"
require_relative "../providers/assume_role_credentials"
require_relative "../providers/mfa_session_credentials"

class AwsAssumeRole::Credentials::Factories::AssumeRole < AwsAssumeRole::Credentials::Factories::AbstractFactory
    include AwsAssumeRole::Credentials::Factories
    type :role_assumption_provider
    priority 30

    def initialize(options)
        if options[:profile]
            try_with_profile(options)
        else
            if options[:use_mfa]
                options[:credentials] = AwsAssumeRole::Credentials::Providers::MfaSessionCredentials.new(options).credentials
            end
            @credentials = AwsAssumeRole::Credentials::Providers::AssumeRoleCredentials.new(options)
        end
    end

    def try_with_profile(options)
        if AwsAssumeRole.shared_config.config_enabled?
            profile = options[:profile]
            region = options[:region]
            @credentials = assume_role_with_profile(options[:profle], options[:region])
        end
        @credentials = assume_role_with_profile(profile, region)
    end

    def assume_role_with_profile(prof, region)
        AwsAssumeRole.shared_config.assume_role_credentials_from_config(
            profile: prof,
            region: region,
        )
    end
end
