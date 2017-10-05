# frozen_string_literal: true

require_relative "includes"
require_relative "../../credentials/factories/default_chain_provider"

class AwsAssumeRole::Cli::Actions::SetEnvironment < AwsAssumeRole::Cli::Actions::AbstractAction
    include AwsAssumeRole::Ui

    SHELL_STRINGS = {
        sh: {
            env_command: "%<key>s=%<value>s; export %<key>s; ",
        },
        csh: {
            env_command: "setenv %<key>s %<value>s; ",
        },
        fish: {
            env_command: "set -x %<key>s %<value>s; ",
            footer: "commands.set_environment.shells.fish",
        },
        powershell: {
            env_command: "set-item ENV:%<key>s %<value>s; ",
            footer: "commands.set_environment.shells.powershell",
        },
    }.freeze

    CommandSchema = proc do
        optional(:profile).filled?
        optional(:region) { filled? > format?(REGION_REGEX) }
        optional(:serial_number) { filled? > format?(MFA_REGEX) }
        optional(:external_id) { filled? > format?(EXTERNAL_ID_REGEX) }
        required(:shell_type).value(included_in?: SHELL_STRINGS.stringify_keys.keys)
        required(:role_arn).maybe { filled? > format?(ROLE_REGEX) }
        required(:role_session_name).maybe { filled? > format?(ROLE_SESSION_NAME_REGEX) }
        required(:duration_seconds).maybe
        rule(role_specification: %i[profile role_arn role_session_name duration_seconds]) do |p, r, s, d|
            (p.filled? | p.empty? & r.filled?) & (r.filled? > s.filled? & d.filled?)
        end
    end

    def act_on(config)
        credentials = try_for_credentials config.to_h
        shell_strings = SHELL_STRINGS[config.shell_type.to_sym]
        str = ""
        [
            [:access_key_id, "AWS_ACCESS_KEY_ID"],
            [:secret_access_key, "AWS_SECRET_ACCESS_KEY"],
            [:session_token, "AWS_SESSION_TOKEN"],
        ].each do |key|
            value = credentials.credentials.send key[0]
            next if value.blank?
            str << format(shell_strings[:env_command], key: key[1], value: value)
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
