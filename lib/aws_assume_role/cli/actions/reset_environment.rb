# frozen_string_literal: true

require_relative "includes"

class AwsAssumeRole::Cli::Actions::ResetEnvironment < AwsAssumeRole::Cli::Actions::AbstractAction
    include AwsAssumeRole::Ui

    SHELL_STRINGS = {
        sh: {
            env_command: "unset %<key>s; ",
        },
        csh: {
            env_command: "unset %<key>s; ",
        },
        fish: {
            env_command: "set -ex %<key>s; ",
            footer: "commands.reset_environment.shells.fish",
        },
        powershell: {
            env_command: "remove-item ENV:%<key>s; ",
            footer: "commands.reset_environment.shells.powershell",
        },
    }.freeze

    CommandSchema = proc do
        required(:shell_type).value(included_in?: SHELL_STRINGS.stringify_keys.keys)
    end

    def act_on(config)
        shell_strings = SHELL_STRINGS[config.shell_type.to_sym]
        str = String.new("")
        %w[AWS_ACCESS_KEY_ID
           AWS_SECRET_ACCESS_KEY
           AWS_SESSION_TOKEN
           AWS_PROFILE
           AWS_ASSUME_ROLE_LOG_LEVEL
           GLI_DEBUG
           AWS_ASSUME_ROLE_KEYRING_BACKEND].each do |key|
            str << format(shell_strings[:env_command], key: key) if ENV.fetch(key, false)
        end
        str << "# #{pastel.yellow t(shell_strings.fetch(:footer, 'commands.set_environment.shells.others'))}"
        puts str
    rescue KeyError, Aws::Errors::NoSuchProfileError
        error format(t("errors.NoSuchProfileError"), config.profile)
        raise
    rescue Aws::Errors::MissingCredentialsError
        error t("errors.MissingCredentialsError")
        raise
    end
end
