# frozen_string_literal: true

require_relative "includes"
require_relative "logging"

class AwsAssumeRole::ProfileConfiguration < Dry::Struct
    include AwsAssumeRole::Logging
    transform_types { |t| t.meta(omittable: true) }

    attribute :access_key_id, Dry::Types["strict.string"].optional.meta(omittable: true)
    attribute :credentials, Dry::Types["any"].optional.meta(omittable: true)
    attribute :secret_access_key, Dry::Types["strict.string"].optional.meta(omittable: true)
    attribute :session_token, Dry::Types["strict.string"].optional.meta(omittable: true)
    attribute :duration_seconds, Dry::Types["coercible.integer"].optional.meta(omittable: true)
    attribute :external_id, Dry::Types["strict.string"].optional.meta(omittable: true)
    attribute :path, Dry::Types["strict.string"].optional.meta(omittable: true)
    attribute :persist_session, Dry::Types["strict.bool"].optional.default(true).meta(omittable: true)
    attribute :profile, Dry::Types["strict.string"].optional.meta(omittable: true)
    attribute :region, Dry::Types["strict.string"].optional.meta(omittable: true)
    attribute :role_arn, Dry::Types["strict.string"].optional.meta(omittable: true)
    attribute :role_session_name, Dry::Types["strict.string"].optional.meta(omittable: true)
    attribute :serial_number, Dry::Types["strict.string"].optional.meta(omittable: true)
    attribute :mfa_serial, Dry::Types["strict.string"].optional.meta(omittable: true)
    attribute :yubikey_oath_name, Dry::Types["strict.string"].optional.meta(omittable: true)
    attribute :use_mfa, Dry::Types["strict.bool"].default(false)
    attribute :no_profile, Dry::Types["strict.bool"].default(false)
    attribute :shell_type, Dry::Types["strict.string"].optional.meta(omittable: true)
    attribute :source_profile, Dry::Types["strict.string"].optional.meta(omittable: true)
    attribute :args, Dry::Types["strict.array"].default([],shared: true)
    attribute :instance_profile_credentials_retries, Dry::Types["strict.integer"].default(0)
    attribute :instance_profile_credentials_timeout, Dry::Types["coercible.float"].default(1.0)

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
        to_hash
    end
end
