require_relative "abstract_factory"
require_relative "../providers/shared_keyring_credentials"

class AwsAssumeRole::Credentials::Factories::SharedKeyring < AwsAssumeRole::Credentials::Factories::AbstractFactory
    type :credential_provider
    priority 19

    def initialize(options = {})
        profile = options[:profile]
        @credentials = if profile
                           AwsAssumeRole::Credentials::Providers::SharedKeyringCredentials.new(profile_name: profile)
                       else
                           AwsAssumeRole::Credentials::Providers::SharedKeyringCredentials.new(profile_name: "default")
                       end
    rescue Aws::Errors::NoSuchProfileError
        nil
    end

    def mfa_completed
        broadcast(:mfa_completed)
    end

    def role_assumption_completed
        broadcast(:role_assumption_completed)
    end
end
