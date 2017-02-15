require_relative "includes"

module AwsAssumeRole::Ui
    include AwsAssumeRole

    ::I18n.load_path += Dir.glob(File.join(File.realpath(__dir__), "..", "..", "i18n", "*.{rb,yml,yaml}"))
    ::I18n.locale = ENV.fetch("LANG", nil).split(".").first.split("_").first || I18n.default_locale

    module_function

    def out(text)
        puts text
    end

    def pastel
        @pastel ||= Pastel.new
    end

    def input
        @input ||= HighLine.new
    end

    def validation_errors_to_s(result)
        text = result.errors.keys.map do |k|
            "#{k} #{result.errors[k].join(';')}"
        end.join(" ")
        text
    end

    def error(text)
        puts pastel.red(text)
    end

    def show_validation_errors(result)
        error validation_errors_to_s(result)
    end

    def ask_with_validation(variable_name, question, type: Dry::Types["coercible.string"], &block)
        STDOUT.puts pastel.yellow question
        validator = Dry::Validation.Schema do
            configure do
                config.messages = :i18n
            end
            required(variable_name) { instance_eval(&block) }
        end
        result = validator.call(variable_name => type[STDIN.gets.chomp])
        return result.to_h[variable_name] if result.success?
        show_validation_errors result
        ask_with_validation variable_name, question, &block

        #    rescue
        #        ask_with_validation question, &block
    end

    def t(*options)
        ::I18n.t(options).first
    end
end
