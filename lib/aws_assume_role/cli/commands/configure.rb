require_relative "../actions/configure_profile"
require_relative "../actions/configure_role_assumption"

module AwsAssumeRole::Cli
    desc t "commands.configure.desc"
    long_desc t "commands.configure.long_desc"
    command :configure do |c|
        c.flag [:p, "profile"], desc: t("options.profile_name")
        c.action do |global_options, options, args|
            AwsAssumeRole::Cli::Actions::ConfigureProfile.new(global_options, options, args)
        end

        c.desc t "commands.configure.desc"
        c.long_desc t "commands.configure.long_desc"
        c.command :role do |r|
            r.flag ["source-profile"], desc: t("options.source_profile")
            r.flag ["role-session-name"], desc: t("options.role_session_name")
            r.flag ["role-arn"], desc: t("options.role_arn")
            r.flag ["mfa-serial"], desc: t("options.mfa_serial")
            r.flag ["region"], desc: t("options.region")
            r.flag ["external-id"], desc: t("options.external_id")
            r.flag ["duration-seconds"], desc: t("options.duration_seconds"), default_value: 3600

            r.action do |global_options, options, args|
                AwsAssumeRole::Cli::Actions::ConfigureRoleAssumption.new(global_options, options, args)
            end
        end
    end
end
