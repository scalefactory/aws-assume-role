# frozen_string_literal: true

require_relative "../actions/migrate_profile"

module AwsAssumeRole::Cli
    desc t "commands.migrate.desc"
    command :migrate do |c|
        c.flag [:p, "profile"], desc: t("options.profile_name")
        c.action do |global_options, options, args|
            AwsAssumeRole::Cli::Actions::MigrateProfile.new(global_options, options, args)
        end
    end
end
