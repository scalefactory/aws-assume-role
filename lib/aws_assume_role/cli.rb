# frozen_string_literal: true

require_relative "includes"
require_relative "ui"
require_relative "logging"

module AwsAssumeRole::Cli
    include AwsAssumeRole
    include AwsAssumeRole::Ui
    include AwsAssumeRole::Logging
    logger.debug "Bootstrapping"
    include GLI::DSL
    include GLI::App
    extend self # rubocop:disable Style/ModuleFunction

    commands_from File.join(File.realpath(__dir__), "cli", "commands")
    program_desc t "program_description"

    exit run(ARGV)
end
