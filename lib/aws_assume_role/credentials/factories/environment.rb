require_relative "abstract_factory"

class AwsAssumeRole::Credentials::Factories::Environment < AwsAssumeRole::Credentials::Factories::AbstractFactory
    type :credential_provider
    priority 10

    def initialize(_options, **)
        key =    %w(AWS_ACCESS_KEY_ID AMAZON_ACCESS_KEY_ID AWS_ACCESS_KEY)
        secret = %w(AWS_SECRET_ACCESS_KEY AMAZON_SECRET_ACCESS_KEY AWS_SECRET_KEY)
        token =  %w(AWS_SESSION_TOKEN AMAZON_SESSION_TOKEN)
        region = %w(AWS_DEFAULT_REGION)
        profile = %w(AWS_PROFILE)
        @credentials = Aws::Credentials.new(envar(key), envar(secret), envar(token))
        @region = envar(region)
        @profile = envar(profile)
    end

    def envar(keys)
        keys.each do |key|
            return ENV[key] if ENV.key?(key)
        end
        nil
    end
end
