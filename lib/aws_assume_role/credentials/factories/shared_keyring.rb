require_relative "abstract_factory"
require_relative "../providers/shared_keyring_credentials"

class AwsAssumeRole::Credentials::Factories::SharedKeyring < AwsAssumeRole::Credentials::Factories::AbstractFactory
    type :credential_provider
    priority 19

    def initialize(options = {})
        @profile = options[:profile] || "default"
        @credentials = AwsAssumeRole::Credentials::Providers::SharedKeyringCredentials.new(profile_name: @profile)
        @region = AwsAssumeRole.shared_config.profile_region(@profile)
    rescue Aws::Errors::NoSuchProfileError
        nil
    end
end
