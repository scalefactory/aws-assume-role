# frozen_string_literal: true

require_relative "includes"
require_relative "../../profile_configuration"

class AwsAssumeRole::Cli::Actions::AbstractAction
    include AwsAssumeRole
    include AwsAssumeRole::Types
    include AwsAssumeRole::Ui
    include AwsAssumeRole::Logging
    CommandSchema = proc { raise "CommandSchema Not implemented" }

    def initialize(global_options, options, args)
        config = ProfileConfiguration.new_from_cli(global_options, options, args)
        logger.debug "Config initialized with #{config.to_hash}"
        result = validate_options(config.to_hash)
        logger.debug "Config validated as #{result.to_hash}"
        result.success? ? act_on(config) : Ui.show_validation_errors(result)
    end

    private

    def try_for_credentials(config)
        @provider ||= AwsAssumeRole::Credentials::Factories::DefaultChainProvider.new(config.to_hash)
        creds = @provider.resolve(nil_with_role_not_set: true)
        logger.debug "Got credentials #{creds}"
        return creds unless creds.nil?
    rescue Smartcard::PCSC::Exception
        error t("errors.SmartcardException")
        exit 403
    rescue NoMethodError
        error t("errors.MissingCredentialsError")
        exit 404
    end

    def resolved_region
        @provider.region
    end

    def resolved_profile
        @provider.profile
    end

    def validate_options(options)
        command_schema = self.class::CommandSchema
        ::Dry::Validation.Schema do
            configure { config.messages = :i18n }
            instance_eval(&command_schema)
        end.call(options)
    end

    def prompt_for_option(key, option_name, validator, fmt: nil)
        text_lookup = t("options.#{key}")
        text = fmt.nil? ? text_lookup : format(text_lookup, fmt)
        Ui.ask_with_validation(option_name, text) { instance_eval(&validator) }
    end

    def act_on(_options)
        raise "Act On Not Implemented"
    end
end
