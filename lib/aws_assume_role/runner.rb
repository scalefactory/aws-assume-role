require_relative "includes"
require_relative "logging"

class AwsAssumeRole::Runner < Dry::Struct
    include AwsAssumeRole::Logging
    constructor_type :schema
    attribute :command, Dry::Types["coercible.array"].of(Dry::Types["strict.string"]).default([])
    attribute :exit_on_error, Dry::Types["strict.bool"].default(true)
    attribute :expected_exit_code, Dry::Types["strict.int"].default(0)
    attribute :environment, Dry::Types["strict.hash"].default({})
    attribute :credentials, Dry::Types["object"].optional

    def initialize(options)
        super(options)
        command_to_exec = command.join(" ")
        process_credentials unless credentials.blank?
        system environment, command_to_exec
        exit_status = $CHILD_STATUS.exitstatus
        process_error(exit_status) if exit_status != expected_exit_code
    end

    private

    def process_credentials
        cred_env = {
            "AWS_ACCESS_KEY_ID" => credentials.credentials.access_key_id,
            "AWS_SECRET_ACCESS_KEY" => credentials.credentials.secret_access_key,
            "AWS_SESSION_TOKEN" => credentials.credentials.session_token,
        }
        @environment = environment.merge cred_env
    end

    def process_error(exit_status)
        logger.error "#{command} failed with #{exit_status}"
        exit exit_status if exit_on_error
        raise "#{command} failed with #{exit_status}"
    end
end
