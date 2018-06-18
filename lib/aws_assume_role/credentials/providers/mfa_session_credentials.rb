# frozen_string_literal: true

require_relative "includes"
require_relative "../../types"
require_relative "../../configuration"
begin
    require "smartcard"
    require "yubioath"
    SMARTCARD_SUPPORT = true
rescue LoadError
    SMARTCARD_SUPPORT = false
end

class AwsAssumeRole::Credentials::Providers::MfaSessionCredentials < Dry::Struct
    include AwsAssumeRole::Vendored::Aws::CredentialProvider
    include AwsAssumeRole::Vendored::Aws::RefreshingCredentials
    include AwsAssumeRole::Ui
    include AwsAssumeRole::Logging

    transform_types { |t| t.meta(omittable: true) }

    attribute :permanent_credentials, Dry::Types["object"]
    attribute :credentials, Dry::Types["object"]
    attribute :expiration, Dry::Types["strict.time"].default(Time.now).
        constructor { |v| v.nil? ? Dry::Types::Undefined : v }
    attribute :first_time, Dry::Types["strict.bool"].default(true).
        constructor { |v| v.nil? ? Dry::Types::Undefined : v }
    attribute :persist_session, Dry::Types["strict.bool"].default(true).
        constructor { |v| v.nil? ? Dry::Types::Undefined : v }
    attribute :duration_seconds, Dry::Types["coercible.int"].default(3600).
        constructor { |v| v.nil? ? Dry::Types::Undefined : v }
    attribute :region, AwsAssumeRole::Types::Region
    attribute :serial_number, AwsAssumeRole::Types::MfaSerial.default("automatic").
        constructor { |v| v.nil? ? Dry::Types::Undefined : v }
    attribute :yubikey_oath_name, Dry::Types["strict.string"].optional

    def initialize(options)
        options.each { |key, value| instance_variable_set("@#{key}", value) }
        @permanent_credentials ||= @credentials
        @credentials = nil
        @serial_number = resolve_serial_number(@serial_number)
        AwsAssumeRole::Vendored::Aws::RefreshingCredentials.instance_method(:initialize).bind(self).call(options)
    end

    private

    def keyring_username
        @keyring_username ||= "#{@identity.to_json}|#{@serial_number}"
    end

    def sts_client
        @sts_client ||= Aws::STS::Client.new(region: @region, credentials: @permanent_credentials)
    end

    def prompt_for_token
        text = @first_time ? t("options.mfa_token.first_time") : t("options.mfa_token.other_times")
        Ui.input.ask text
    end

    def initialized
        @first_time = false
    end

    def refresh
        return set_credentials_from_keyring if @persist_session && @first_time
        refresh_using_mfa if near_expiration?
        broadcast(:mfa_completed)
    end

    def retrieve_yubikey_token
        raise t("options.mfa_token.smartcard_not_supported") unless SMARTCARD_SUPPORT
        context = Smartcard::PCSC::Context.new
        raise "Yubikey not found" unless context.readers.length == 1
        reader_name = context.readers.first
        card = Smartcard::PCSC::Card.new(context, reader_name, :shared)
        YubiOATH.new(card).calculate(name: @yubikey_oath_name, timestamp: Time.now)
    end

    def refresh_using_mfa
        token_code = @yubikey_oath_name ? retrieve_yubikey_token : prompt_for_token
        token = sts_client.get_session_token(
            duration_seconds: @duration_seconds,
            serial_number: @serial_number,
            token_code: token_code,
        )
        initialized
        instance_credentials token.credentials
        persist_credentials if @persist_session
    end

    def credentials_from_keyring
        @credentials_from_keyring ||= AwsAssumeRole::Store::Keyring.fetch keyring_username
    rescue Aws::Errors::NoSuchProfileError
        logger.debug "Key not found"
        @credentials_from_keyring = nil
        return nil
    end

    def persist_credentials
        AwsAssumeRole::Store::Keyring.save_credentials keyring_username, @credentials, expiration: @expiration
    end

    def instance_credentials(credentials)
        return unless credentials
        @credentials = AwsAssumeRole::Store::Serialization.credentials_from_hash(credentials)
        @expiration = credentials.respond_to?(:expiration) ? credentials.expiration : Time.parse(credentials[:expiration])
    end

    def set_credentials_from_keyring
        instance_credentials credentials_from_keyring if credentials_from_keyring
        initialized
        refresh_using_mfa unless @credentials && !near_expiration?
    end

    def identity
        @identity ||= sts_client.get_caller_identity
    end

    def resolve_serial_number(serial_number)
        return serial_number unless serial_number.nil? || serial_number == "automatic"
        user_name = identity.arn.split("/")[1]
        "arn:aws:iam::#{identity.account}:mfa/#{user_name}"
    end
end
