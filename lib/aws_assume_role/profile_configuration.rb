require_relative "includes"
require_relative "logging"

class AwsAssumeRole::ProfileConfiguration
    extend Dry::Initializer
    include AwsAssumeRole::Logging
    option :access_key_id, Dry::Types["strict.string"].optional, default: proc { nil }
    option :credentials, default: proc { nil }
    option :secret_access_key, Dry::Types["strict.string"].optional, default: proc { nil }
    option :session_token, Dry::Types["strict.string"].optional, default: proc { nil }
    option :duration_seconds, Dry::Types["coercible.int"].optional, default: proc { nil }
    option :external_id, Dry::Types["strict.string"].optional, default: proc { nil }
    option :persist_session, Dry::Types["strict.bool"], default: proc { true }
    option :profile, Dry::Types["strict.string"].optional, default: proc { nil }
    option :region, Dry::Types["strict.string"].optional, default: proc { nil }
    option :role_arn, Dry::Types["strict.string"].optional, default: proc { nil }
    option :role_session_name, Dry::Types["strict.string"].optional, default: proc { nil }
    option :serial_number, Dry::Types["strict.string"].optional, default: proc { nil }
    option :mfa_serial, Dry::Types["strict.string"].optional, default: proc { nil }
    option :use_mfa, default: proc { false }
    option :no_profile, default: proc { false }
    option :shell_type, Dry::Types["strict.string"].optional, default: proc { nil }
    option :source_profile, Dry::Types["strict.string"].optional, default: proc { nil }
    option :args, default: proc { [] }
    option :instance_profile_credentials_retries, Dry::Types["strict.int"], default: proc { 0 }
    option :instance_profile_credentials_timeout, Dry::Types["coercible.float"], default: proc { 1 }

    attr_writer :credentials

    def self.merge_mfa_variable(options)
        new_hash = options.key?(:mfa_serial) ? options.merge(serial_number: options[:mfa_serial]) : options
        new_hash[:use_mfa] ||= new_hash.fetch(:serial_number, nil) ? true : false
        if new_hash.key?(:serial_number) && new_hash[:serial_number] == "automatic"
            new_hash.delete(:serial_number)
        end
        new_hash
    end

    def self.new_from_cli(global_options, options, args)
        options = global_options.merge options
        options = options.map do |k, v|
            [k.to_s.underscore.to_sym, v]
        end.to_h
        options[:args] = args
        new merge_mfa_variable(options)
    end

    def self.new_from_credential_provider_initialization(options)
        logger.debug "new_from_credential_provider_initialization with #{options.to_h}"
        new_from_credential_provider(options, credentials: nil, delete: [])
    end

    def self.new_from_credential_provider(options = {}, credentials: nil, delete: [])
        option_hash = options.to_h
        config = option_hash.fetch(:config, {}).to_h
        hash_to_merge = option_hash.merge config
        hash_to_merge.merge(credentials: credentials) if credentials
        delete.each do |k|
            hash_to_merge.delete k
        end
        hash = merge_mfa_variable(hash_to_merge)
        logger.debug "new_from_credential_provider with #{hash}"
        new hash
    end

    def to_h
        instance_values.delete("__options__").symbolize_keys
    end

    Dry::Types.register_class(self)
end
