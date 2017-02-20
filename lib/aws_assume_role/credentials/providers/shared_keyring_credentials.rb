require_relative "includes"
require_relative "../../types"

class AwsAssumeRole::Credentials::Providers::SharedKeyringCredentials < ::Aws::SharedCredentials
    include AwsAssumeRole::Logging
    attr_reader :region, :role_arn

    def initialize(options = {})
        logger.debug "SharedKeyringCredentials initiated with #{options}"
        @path = options[:path]
        @path ||= AwsAssumeRole.shared_config.credentials_path
        @profile_name = options[:profile_name] ||= options[:profile]
        @profile_name ||= ENV["AWS_PROFILE"]
        @profile_name ||= AwsAssumeRole.shared_config.profile_name
        logger.debug "SharedKeyringCredentials resolved profile name #{@profile_name}"
        config = determine_config(@path, @profile_name)
        @role_arn = config.profile_hash(@profile_name)
        @region = config.profile_region(@profile_name)
        @role_arn = config.profile_role(@profile_name)
        attempted_credential = config.credentials(options)
        return unless attempted_credential && attempted_credential.set?
        @credentials = attempted_credential
    end

    private

    def determine_config(path, profile_name)
        if path && path == AwsAssumeRole.shared_config.credentials_path
            logger.debug "SharedKeyringCredentials found shared credential path"
            AwsAssumeRole.shared_config
        else
            logger.debug "SharedKeyringCredentials found custom credential path"
            AwsAssumeRole::Store::SharedConfigWithKeyring.new(
                credentials_path: path,
                profile_name: profile_name,
            )
        end
    end
end
