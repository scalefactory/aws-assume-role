require_relative "abstract_factory"

class AwsAssumeRole::Credentials::Factories::Static < AwsAssumeRole::Credentials::Factories::AbstractFactory
    type :credential_provider
    priority 0

    def initialize(options = {})
        @credentials = Aws::Credentials.new(
            options[:access_key_id],
            options[:secret_access_key],
            options[:session_token],
        )
        @region = options[:region]
        @profile = options[:profile]
    end
end
