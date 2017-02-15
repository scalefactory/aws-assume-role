require_relative "abstract_factory"

class AwsAssumeRole::Credentials::Factories::InstanceProfile < AwsAssumeRole::Credentials::Factories::AbstractFactory
    type :role_assumption_provider
    priority 40

    def initialize(options = {})
        @credentials = if ENV["AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"]
                           Aws::ECSCredentials.new(options)
                       else
                           Aws::InstanceProfileCredentials.new(options)
                       end
    end
end
