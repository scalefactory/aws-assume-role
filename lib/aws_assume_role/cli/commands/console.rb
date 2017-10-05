# frozen_string_literal: true

require_relative "../actions/console"

module AwsAssumeRole::Cli
    desc t "commands.console.desc"
    command :console do |c|
        c.flag [:p, "profile"], desc: t("options.profile_name")
        c.flag ["role-session-name"], desc: t("options.role_session_name")
        c.flag ["role-arn"], desc: t("options.role_arn")
        c.flag ["mfa-serial"], desc: t("options.mfa_serial")
        c.flag ["region"], desc: t("options.region")
        c.flag ["external-id"], desc: t("options.external_id")
        c.flag ["duration-seconds"], desc: t("options.duration_seconds"), default_value: 3600
        c.action do |global_options, options, args|
            AwsAssumeRole::Cli::Actions::Console.new(global_options, options, args)
        end
    end
end
