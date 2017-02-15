require_relative "includes"
require_relative "../../types"

class AwsAssumeRole::Credentials::Providers::SharedKeyringCredentials < ::Aws::SharedCredentials
    def initialize(options = {})
        shared_config = AwsAssumeRole.shared_config
        @path = options[:path]
        @path ||= shared_config.credentials_path
        @profile_name = options[:profile_name]
        @profile_name ||= ENV["AWS_PROFILE"]
        @profile_name ||= shared_config.profile_name
        if @path && @path == shared_config.credentials_path
            @credentials = shared_config.credentials(profile: @profile_name)
        else
            config = AwsAssumeRole::Store::SharedConfig.new(
                credentials_path: @path,
                profile_name: @profile_name,
            )
            @credentials = config.credentials(profile: @profile_name)
        end
    end
end
