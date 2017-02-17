require_relative "abstract_factory"
require_relative "../providers/shared_keyring_credentials"

class AwsAssumeRole::Credentials::Factories::Shared < AwsAssumeRole::Credentials::Factories::AbstractFactory
    type :credential_provider
    priority 30

    def initialize(options = {})
        logger.debug "Shared Factory initiated with #{options}"
        @profile = options[:profile]
        @credentials = AwsAssumeRole::Credentials::Providers::SharedKeyringCredentials.new(options)
        @region = @credentials.region
        @role_arn = @credentials.role_arn
    rescue Aws::Errors::NoSuchProfileError
        nil
    end
end
