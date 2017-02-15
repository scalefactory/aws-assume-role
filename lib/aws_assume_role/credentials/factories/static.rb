require_relative "abstract_factory"

class AwsAssumeRole::Credentials::Factories::Static < AwsAssumeRole::Credentials::Factories::AbstractFactory
    type :credential_provider
    priority 0

    def initialize(access_key_id: nil, secret_access_key: nil, region: nil, session_token: nil, **)
        @credentials = Aws::Credentials.new(
            access_key_id,
            secret_access_key,
            session_token,
        )
        @region = region
    end
end
