# frozen_string_literal: true

require_relative "includes"
require_relative "../../runner"
require "cgi"
require "json"

class AwsAssumeRole::Cli::Actions::Console < AwsAssumeRole::Cli::Actions::AbstractAction
    include AwsAssumeRole::Ui
    include AwsAssumeRole::Logging

    FEDERATION_URL = "https://signin.aws.amazon.com/federation".freeze
    CONSOLE_URL = "https://console.aws.amazon.com".freeze
    GENERIC_SIGNIN_URL = "https://signin.aws.amazon.com/console".freeze
    SIGNIN_URL = [FEDERATION_URL, "?Action=getSigninToken", "&Session=%s"].join
    LOGIN_URL = [FEDERATION_URL, "?Action=login", "&Destination=%s", "&SigninToken=%s"].join

    CommandSchema = proc do
        required(:profile).maybe
        optional(:region) { filled? > format?(REGION_REGEX) }
        optional(:serial_number) { filled? > format?(MFA_REGEX) }
        required(:role_arn).maybe
        required(:role_session_name).maybe
        required(:duration_seconds).maybe
        rule(role_specification: %i[profile role_arn role_session_name duration_seconds]) do |p, r, s, d|
            (p.filled? | p.empty? & r.filled?) & (r.filled? > s.filled? & d.filled?)
        end
    end

    def try_federation(config)
        credentials = try_for_credentials config.to_h
        return unless credentials.set?
        session = session_json(credentials)
        signin_url = format SIGNIN_URL, CGI.escape(session)
        sso_token = JSON.parse(URI.parse(signin_url).read)["SigninToken"]
        format LOGIN_URL, CGI.escape(CONSOLE_URL), CGI.escape(sso_token)
    rescue OpenURI::HTTPError
        error "Error getting federated session, forming simple switch URL instead"
    end

    def session_json(credentials)
        {
            sessionId: credentials.credentials.access_key_id,
            sessionKey: credentials.credentials.secret_access_key,
            sessionToken: credentials.credentials.session_token,
        }.to_json
    end

    def try_switch_url(config)
        profile = AwsAssumeRole.shared_config.determine_profile(profile_name: config.profile)
        config_section = AwsAssumeRole.shared_config.parsed_config[profile]
        raise Aws::Errors::NoSuchProfileError if config_section.nil?
        resolved_role_arn = config.role_arn || config_section.fetch("role_arn", nil)
        return unless resolved_role_arn
        components = resolved_role_arn.split(":")
        account = components[4]
        role = components[5].split("/").last
        display_name = config.profile || "#{account}_#{role}"
        format "https://signin.aws.amazon.com/switchrole?account=%s&roleName=%s&displayName=%s", account, role, display_name
    end

    def act_on(config)
        final_url = try_federation(config) || try_switch_url(config) || CONSOLE_URL
        Launchy.open final_url
    rescue KeyError, Aws::Errors::NoSuchProfileError
        error format(t("errors.NoSuchProfileError"), config.profile)
    rescue Aws::Errors::MissingCredentialsError
        error t("errors.MissingCredentialsError")
    end
end
