require_relative "abstract_factory"

class AwsAssumeRole::Credentials::Factories::Shared < AwsAssumeRole::Credentials::Factories::AbstractFactory
    type :credential_provider
    priority 20

    def initialize(options = {})
        profile = options[:profile]
        @credentials = if profile
                           AwsAssumeRole::Vendored::Aws::SharedCredentials.new(profile_name: profile)
                       else
                           AwsAssumeRole::Vendored::Aws::SharedCredentials.new(profile_name: "default")
                       end
    rescue Aws::Errors::NoSuchProfileError
        nil
    end
end
