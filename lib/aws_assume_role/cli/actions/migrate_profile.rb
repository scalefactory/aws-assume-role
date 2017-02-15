require_relative "includes"

class AwsAssumeRole::Cli::Actions::MigrateProfile < AwsAssumeRole::Cli::Actions::AbstractAction
    CommandSchema = proc do
        required(:profile).value(:filled?)
    end

    def act_on(config)
        AwsAssumeRole.shared_config.migrate_profile config.profile
        out format(t("commands.configure.saved"), config[:profile], AwsAssumeRole.shared_config.config_path)
    rescue KeyError, Aws::Errors::NoSuchProfileError
        error format(t("errors.NoSuchProfileError"), config.profile)
        raise
    rescue Aws::Errors::MissingCredentialsError
        error t("errors.MissingCredentialsError")
        raise
    end
end
