# frozen_string_literal: true

require_relative "../actions/list_profiles"

module AwsAssumeRole::Cli
    desc t "commands.list.desc"
    command :list do |c|
        c.action do |global_options, options, args|
            AwsAssumeRole::Cli::Actions::ListProfiles.new(global_options, options, args)
        end
    end
end
