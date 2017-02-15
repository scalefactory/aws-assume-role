require_relative "abstract_factory"

class AwsAssumeRole::Credentials::Factories::Shared < AwsAssumeRole::Credentials::Factories::AbstractFactory
    type :credential_provider
    priority 20

    def initialize(options = {})
        profile = options[:profile] || "default"
        @credentials = AwsAssumeRole::Vendored::Aws::SharedCredentials.new(profile_name: profile)
        @region = AwsAssumeRole.shared_config.profile_region(region)
    rescue Aws::Errors::NoSuchProfileError
        nil
    end
end
