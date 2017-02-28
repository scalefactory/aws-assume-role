require_relative "abstract_action"

class AwsAssumeRole::Cli::Actions::ConfigureRoleAssumption < AwsAssumeRole::Cli::Actions::AbstractAction
    CommandSchema = proc do
        required(:profile)
        required(:source_profile) { str? }
        optional(:region) { filled? > format?(REGION_REGEX) }
        optional(:serial_number) { filled? > format?(MFA_REGEX) }
        required(:role_session_name).filled?
        required(:role_arn) { filled? & format?(ROLE_REGEX) }
        required(:external_id).filled?
        required(:duration_seconds).filled?
        optional(:yubikey_oath_name)
    end

    def act_on(config)
        AwsAssumeRole.shared_config.save_profile(config.profile, config.to_h.compact)
        out format(t("commands.configure.saved"), config.profile, AwsAssumeRole.shared_config.config_path)
    end
end
