require_relative "../actions/run"

module AwsAssumeRole::Cli
    desc t "commands.run.desc"
    command :run do |c|
        c.flag [:p, "profile"], desc: t("options.profile_name"), optional: true
        c.flag ["role-session-name"], desc: t("options.role_session_name")
        c.flag ["role-arn"], desc: t("options.role_arn")
        c.flag ["mfa-serial"], desc: t("options.mfa_serial")
        c.flag ["region"], desc: t("options.region"), optional: true
        c.flag ["external-id"], desc: t("options.external_id"), optional: true
        c.flag ["duration-seconds"], desc: t("options.duration_seconds"), default_value: 3600
        c.switch ["no-profile"], desc: t("options.duration_seconds"), default_value: false
        c.action do |global_options, options, args|
            AwsAssumeRole::Cli::Actions::Run.new(global_options, options, args)
        end
    end
end
