require_relative "../actions/console"

module AwsAssumeRole::Cli
    desc t "commands.console.desc"
    command :console do |c|
        c.flag [:p, "profile"], desc: t("options.profile_name")
        c.flag ["role-arn"], desc: t("options.role_arn")
        c.action do |global_options, options, args|
            AwsAssumeRole::Cli::Actions::Console.new(global_options, options, args)
        end
    end
end
