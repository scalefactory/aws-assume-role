require_relative "includes"
require_relative "validations"
require_relative "../../profile_configuration"

class AwsAssumeRole::Cli::Actions::AbstractAction
    include AwsAssumeRole
    include AwsAssumeRole::Cli::Actions::Validations
    include Ui
    CommandSchema = proc { raise "CommandSchema Not implemented" }

    def initialize(global_options, options, args)
        config = ProfileConfiguration.new_from_cli(global_options, options, args)
        result = validate_options(config.to_h.deep_symbolize_keys)
        return act_on(config) if result.success?
        Ui.show_validation_errors result
    end

    private

    def try_for_credentials(config)
        @provider ||= AwsAssumeRole::Credentials::Factories::DefaultChainProvider.new(config.to_h)
        creds = @provider.resolve
        return creds unless creds.nil?
        error "Cannot find any credentials"
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
        Dry::Validation.Schema do
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
