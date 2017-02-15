require_relative "includes"
require_relative "../../runner"

class AwsAssumeRole::Cli::Actions::Console < AwsAssumeRole::Cli::Actions::AbstractAction
    include AwsAssumeRole::Ui
    include AwsAssumeRole::Logging

    CommandSchema = proc do
        required(:profile).maybe
        required(:role_arn).maybe
        rule(console_role: [:profile, :role_arn]) do |p, r|
            p.filled? | r.filled?
        end
    end

    def try_role_arn(config)
        profile = AwsAssumeRole.shared_config.determine_profile(profile_name: config.profile)
        resolved_role_arn = config.role_arn || AwsAssumeRole.shared_config.parsed_config[profile]["role_arn"]
        return unless resolved_role_arn
        components = resolved_role_arn.split(":")
        account = components[4]
        role = components[5].split("/").last
        display_name = config.profile || "#{account}_#{role}"
        format "https://signin.aws.amazon.com/switchrole?account=%s&roleName=%s&displayName=%s", account, role, display_name
    end

    def act_on(config)
        url = try_role_arn(config) || "https://signin.aws.amazon.com/console"
        Launchy.open format url
    rescue KeyError, Aws::Errors::NoSuchProfileError
        error "Cannot find profile"
    rescue NoMethodError
        error "Role ARN not specified correctly"
    end
end
