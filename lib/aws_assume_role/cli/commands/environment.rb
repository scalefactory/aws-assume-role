require_relative "../actions/set_environment"
require_relative "../actions/reset_environment"

module AwsAssumeRole::Cli
    desc t "commands.set_environment.desc"
    long_desc t "commands.set_environment.long_desc"
    command :environment do |c|
        desc t "commands.set_environment.desc"
        long_desc t "commands.set_environment.long_desc"
        c.command :set do |s|
            s.flag [:p, "profile"], desc: t("options.profile_name")
            s.flag [:s, "shell-type"], desc: t("options.shell_type"), default_value: "sh"
            s.flag ["role-session-name"], desc: t("options.role_session_name")
            s.flag ["role-arn"], desc: t("options.role_arn")
            s.flag ["mfa-serial"], desc: t("options.mfa_serial")
            s.flag ["region"], desc: t("options.region")
            s.flag ["external-id"], desc: t("options.external_id")
            s.flag ["duration-seconds"], desc: t("options.duration_seconds"), default_value: 3600
            s.action do |global_options, options, args|
                AwsAssumeRole::Cli::Actions::SetEnvironment.new(global_options, options, args)
            end
        end

        desc t "commands.reset_environment.desc"
        long_desc t "commands.reset_environment.long_desc"
        c.command :reset do |s|
            s.action do |global_options, options, args|
                AwsAssumeRole::Cli::Actions::ResetEnvironment.new(global_options, options, args)
            end
        end
    end
end
