require_relative "abstract_factory"
require_relative "../providers/shared_keyring_credentials"

class AwsAssumeRole::Credentials::Factories::SharedKeyring < AwsAssumeRole::Credentials::Factories::AbstractFactory
    type :credential_provider
    priority 19

    def initialize(options = {})
        @profile = options[:profile] || "default"
        @credentials = AwsAssumeRole::Credentials::Providers::SharedKeyringCredentials.new(profile_name: @profile)
        @region = AwsAssumeRole.shared_config.profile_region(@profile)
        @role_arn = AwsAssumeRole.shared_config.profile_role(@profile)
        if options[:use_mfa] || options[:mfa_serial] || options[:serial_number]
            new_options = options.merge(credentials: credentials, region: region)
            @credentials = AwsAssumeRole::Credentials::Providers::MfaSessionCredentials.new(new_options)
        end
    rescue Aws::Errors::NoSuchProfileError
        nil
    end
end
