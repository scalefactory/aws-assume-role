require_relative "includes"
require_relative "ui"

module AwsAssumeRole::Cli
    include GLI::DSL
    include GLI::App
    include AwsAssumeRole
    include AwsAssumeRole::Ui
    extend self # rubocop:disable Style/ModuleFunction

    commands_from File.join(File.realpath(__dir__), "cli", "commands")
    program_desc t "program_description"

    exit run(ARGV)
end
