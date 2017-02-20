require_relative "abstract_factory"

class AwsAssumeRole::Credentials::Factories::InstanceProfile < AwsAssumeRole::Credentials::Factories::AbstractFactory
    type :instance_role_provider
    priority 40

    def initialize(options = {})
        options[:retries] ||= options[:instance_profile_credentials_retries] || 0
        options[:http_open_timeout] ||= options[:instance_profile_credentials_timeout] || 1
        options[:http_read_timeout] ||= options[:instance_profile_credentials_timeout] || 1
        @credentials = if ENV["AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"]
                           Aws::ECSCredentials.new(options)
                       else
                           Aws::InstanceProfileCredentials.new(options)
                       end
    end
end
