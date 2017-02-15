require_relative "includes"
require_relative "../../credentials/factories/default_chain_provider"

class AwsAssumeRole::Cli::Actions::Test < AwsAssumeRole::Cli::Actions::AbstractAction
    include AwsAssumeRole::Ui

    CommandSchema = proc do
        required(:profile).maybe
        optional(:region) { filled? > format?(REGION_REGEX) }
        optional(:serial_number) { filled? > format?(MFA_REGEX) }
        required(:role_arn).maybe
        required(:role_session_name).maybe
        required(:duration_seconds).maybe
        rule(role_specification: [:profile, :role_arn, :role_session_name, :duration_seconds]) do |p, r, s, d|
            (p.filled? | p.empty? & r.filled?) & (r.filled? > s.filled? & d.filled?)
        end
    end

    def act_on(config)
        credentials = try_for_credentials config.to_h
        client = Aws::STS::Client.new(credentials: credentials, region: resolved_region)
        identity = client.get_caller_identity
        out format(t("commands.test.output"), identity.account, identity.arn, identity.user_id)
    rescue KeyError, Aws::Errors::NoSuchProfileError
        error format(t("errors.NoSuchProfileError"), config.profile)
        raise
    rescue Aws::Errors::MissingCredentialsError
        error t("errors.MissingCredentialsError")
        raise
    end
end
