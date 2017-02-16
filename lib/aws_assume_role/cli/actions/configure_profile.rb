require_relative "abstract_action"
require_relative "../../store/shared_config_with_keyring"

class AwsAssumeRole::Cli::Actions::ConfigureProfile < AwsAssumeRole::Cli::Actions::AbstractAction
    CommandSchema = proc do
        required(:profile)
        optional(:region) { filled? > format?(REGION_REGEX) }
        optional(:mfa_serial)
        optional(:profile_name)
    end

    def act_on(config)
        new_hash = config.to_h
        profile = config.profile || prompt_for_option(:profile_name, "profile", proc { filled? })
        new_hash[:region] = prompt_for_option(:region, "region", proc { filled? > format?(REGION_REGEX) })
        new_hash[:aws_access_key_id] = prompt_for_option(:aws_access_key_id, "aws_access_key_id", ACCESS_KEY_VALIDATOR)
        new_hash[:aws_secret_access_key] = prompt_for_option(:aws_secret_access_key, "aws_secret_access_key", proc { filled? })
        AwsAssumeRole.shared_config.save_profile(profile, new_hash)
        out format(t("commands.configure.saved"), config.profile, AwsAssumeRole.shared_config.config_path)
    end
end
