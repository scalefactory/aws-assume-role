require_relative "includes"

class AwsAssumeRole::Cli::Actions::MigrateProfile < AwsAssumeRole::Cli::Actions::AbstractAction
    CommandSchema = proc do
        required(:profile).value(:filled?)
    end

    def act_on(config)
        require "pry"
        AwsAssumeRole.shared_config.migrate_profile config.profile
        out format(t("commands.configure.saved"), config[:profile], AwsAssumeRole.shared_config.config_path)
    rescue KeyError, Aws::Errors::NoSuchProfileError
        error format t("commands.delete.not_found"), config.profile
    end
end
