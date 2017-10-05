# frozen_string_literal: true

require_relative "includes"
require_relative "../../store/shared_config_with_keyring"

class AwsAssumeRole::Cli::Actions::DeleteProfile < AwsAssumeRole::Cli::Actions::AbstractAction
    CommandSchema = proc do
        required(:profile).value(:filled?)
    end

    def act_on(config)
        prompt_for_option(:name_to_delete, "Name", proc { eql? config.profile }, fmt: config.profile)
        AwsAssumeRole.shared_config.delete_profile config.profile
        out format t("commands.delete.completed"), config.profile
    rescue KeyError, Aws::Errors::NoSuchProfileError
        error format(t("errors.NoSuchProfileError"), config.profile)
        raise
    rescue Aws::Errors::MissingCredentialsError
        error t("errors.MissingCredentialsError")
        raise
    end
end
