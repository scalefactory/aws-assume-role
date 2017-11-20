# frozen_string_literal: true

require_relative "includes"
require_relative "../logging"
require_relative "keyring"
require_relative "../profile_configuration"
require_relative "../credentials/providers/mfa_session_credentials"

class AwsAssumeRole::Store::SharedConfigWithKeyring < AwsAssumeRole::Vendored::Aws::SharedConfig
    include AwsAssumeRole::Store
    include AwsAssumeRole::Logging

    attr_reader :parsed_config

    # @param [Hash] options
    # @option options [String] :credentials_path Path to the shared credentials
    #   file. Defaults to "#{Dir.home}/.aws/credentials".
    # @option options [String] :config_path Path to the shared config file.
    #   Defaults to "#{Dir.home}/.aws/config".
    # @option options [String] :profile_name The credential/config profile name
    #   to use. If not specified, will check `ENV['AWS_PROFILE']` before using
    #   the fixed default value of 'default'.
    # @option options [Boolean] :config_enabled If true, loads the shared config
    #   file and enables new config values outside of the old shared credential
    #   spec.
    def initialize(options = {})
        @profile_name = determine_profile(options)
        @config_enabled = options[:config_enabled]
        @credentials_path = options[:credentials_path] ||
                            determine_credentials_path
        @parsed_credentials = {}
        load_credentials_file if loadable?(@credentials_path)
        return unless @config_enabled
        @config_path = options[:config_path] || determine_config_path
        load_config_file if loadable?(@config_path)
    end

    # @api private
    def fresh(options = {})
        @configuration = nil
        @semaphore = nil
        @assume_role_shared_config = nil
        @profile_name = nil
        @credentials_path = nil
        @config_path = nil
        @parsed_credentials = {}
        @parsed_config = nil
        @config_enabled = options[:config_enabled] ? true : false
        @profile_name = determine_profile(options)
        @credentials_path = options[:credentials_path] ||
                            determine_credentials_path
        load_credentials_file if loadable?(@credentials_path)
        return unless @config_enabled
        @config_path = options[:config_path] || determine_config_path
        load_config_file if loadable?(@config_path)
    end

    def credentials(opts = {})
        logger.debug "SharedConfigWithKeyring asked for credentials with opts #{opts}"
        p = opts[:profile] || @profile_name
        validate_profile_exists(p) if credentials_present?
        credentials_from_keyring(p, opts) || credentials_from_shared(p, opts) || credentials_from_config(p, opts)
    end

    def save_profile(profile_name, hash)
        ckey = "profile #{profile_name}"
        merged_config = configuration[ckey].deep_symbolize_keys.merge hash.to_h
        merged_config[:mfa_serial] = merged_config[:serial_number] if merged_config[:serial_number]
        credentials = Aws::Credentials.new(merged_config.delete(:aws_access_key_id),
                                           merged_config.delete(:aws_secret_access_key))
        semaphore.synchronize do
            Keyring.save_credentials profile_name, credentials if credentials.set?
            merged_config = merged_config.slice :region, :role_arn, :mfa_serial, :source_profile,
                                                :role_session_name, :external_id, :duration_seconds,
                                                :yubikey_oath_name
            configuration.delete_section ckey
            configuration[ckey] = merged_config.compact
            save_configuration
        end
    end

    def profiles
        configuration.sections.map { |c| c.gsub("profile ", "") }
    end

    def delete_profile(profile_name)
        # Keyring does not return errors for non-existent things, so always attempt.
        Keyring.delete_credentials(profile_name)
        semaphore.synchronize do
            raise KeyError if configuration["profile #{profile_name}"].blank?
            configuration.delete_section("profile #{profile_name}")
            save_configuration
        end
    end

    def migrate_profile(profile_name)
        validate_profile_exists(profile_name)
        save_profile(profile_name, configuration["profile #{profile_name}"])
    end

    def profile_region(profile_name)
        resolve_profile_parameter(profile_name, "region")
    end

    def profile_role(profile_name)
        resolve_profile_parameter(profile_name, "role_arn")
    end

    def profile_hash(profile_name)
        {} || @parsed_config[profile_key(profile_name)]
    end

    private

    def profile_key(profile)
        logger.debug "About to lookup #{profile}"
        if profile == "default" || profile.nil? || profile == ""
            "default"
        else
            profile
        end
    end

    def resolve_profile_parameter(profile_name, param)
        return unless @parsed_config
        prof_cfg = @parsed_config[profile_key(profile_name)]
        resolve_parameter(param, @parsed_config, prof_cfg)
    end

    def resolve_parameter(param, cfg, prof_cfg)
        return unless prof_cfg && cfg
        return prof_cfg[param] if prof_cfg.key? param
        source_profile = prof_cfg["source_profile"]
        return unless source_profile
        source_cfg = cfg[source_profile]
        return unless source_cfg
        cfg[prof_cfg["source_profile"]][param] if source_cfg.key?(param)
    end

    def resolve_region(cfg, prof_cfg)
        resolve_parameter("region", cfg, prof_cfg)
    end

    def resolve_arn(cfg, prof_cfg)
        resolve_parameter("role_arn", cfg, prof_cfg)
    end

    def assume_role_from_profile(cfg, profile, opts)
        logger.debug "Entering assume_role_from_profile with #{cfg}, #{profile}, #{opts}"
        prof_cfg = cfg[profile]
        return unless cfg && prof_cfg
        opts[:source_profile] ||= prof_cfg["source_profile"]
        if opts[:source_profile]
            opts[:credentials] = credentials(profile: opts[:source_profile])
            if opts[:credentials]
                opts[:role_session_name] ||= prof_cfg["role_session_name"]
                opts[:role_session_name] ||= "default_session"
                opts[:role_arn] ||= prof_cfg["role_arn"]
                opts[:external_id] ||= prof_cfg["external_id"]
                opts[:serial_number] ||= prof_cfg["mfa_serial"]
                opts[:yubikey_oath_name] ||= prof_cfg["yubikey_oath_name"]
                opts[:region] ||= profile_region(profile)
                if opts[:serial_number]
                    mfa_opts = {
                        credentials: opts[:credentials],
                        region: opts[:region],
                        serial_number: opts[:serial_number],
                        yubikey_oath_name: opts[:yubikey_oath_name],
                    }
                    mfa_creds = mfa_session(cfg, opts[:source_profile], mfa_opts)
                    opts.delete :serial_number
                end
                opts[:credentials] = mfa_creds if mfa_creds
                opts[:profile] = opts.delete(:source_profile)
                AwsAssumeRole::Credentials::Providers::AssumeRoleCredentials.new(opts)
            else
                raise ::Aws::Errors::NoSourceProfileError, "Profile #{profile} has a role_arn, and source_profile, but the"\
                      " source_profile does not have credentials."
            end
        elsif prof_cfg["role_arn"]
            raise ::Aws::Errors::NoSourceProfileError, "Profile #{profile} has a role_arn, but no source_profile."
        end
    end

    def mfa_session(cfg, profile, opts)
        prof_cfg = cfg[profile]
        return unless cfg && prof_cfg
        opts[:serial_number] ||= opts[:mfa_serial] || prof_cfg["mfa_serial"]
        opts[:source_profile] ||= prof_cfg["source_profile"]
        opts[:region] ||= profile_region(profile)
        return unless opts[:serial_number]
        opts[:credentials] ||= credentials(profile: opts[:profile])
        AwsAssumeRole::Credentials::Providers::MfaSessionCredentials.new(opts)
    end

    def credentials_from_keyring(profile, opts)
        logger.debug "Entering credentials_from_keyring"
        return unless @parsed_config
        logger.debug "credentials_from_keyring: @parsed_config found"
        prof_cfg = @parsed_config[profile]
        return unless prof_cfg
        logger.debug "credentials_from_keyring: prof_cfg found"
        opts[:serial_number] ||= opts[:mfa_serial] || prof_cfg[:mfa_serial] || prof_cfg[:serial_number]
        if opts[:serial_number]
            logger.debug "credentials_from_keyring detected mfa requirement"
            mfa_session(@parsed_config, profile, opts)
        else
            logger.debug "Attempt to fetch #{profile} from keyring"
            keyring_creds = Keyring.fetch(profile)
            return unless keyring_creds
            creds = Serialization.credentials_from_hash Keyring.fetch(profile)
            creds if credentials_complete(creds)
        end
    rescue Aws::Errors::NoSourceProfileError, Aws::Errors::NoSuchProfileError
        nil
    end

    def semaphore
        @semaphore ||= Mutex.new
    end

    def configuration
        @configuration ||= IniFile.new(filename: determine_config_path, default: "default")
    end

    # Please run in a mutex
    def save_configuration
        if File.exist? determine_config_path
            bytes_required = File.size(determine_config_path)
            random_bytes = SecureRandom.random_bytes(bytes_required)
            File.write(determine_config_path, random_bytes)
        else
            FileUtils.mkdir_p(Pathname.new(determine_config_path).dirname)
        end
        configuration.save
    end
end

module AwsAssumeRole
    module_function

    def shared_config
        enabled = ENV["AWS_SDK_CONFIG_OPT_OUT"] ? false : true
        @assume_role_shared_config ||= ::AwsAssumeRole::Store::SharedConfigWithKeyring.new(config_enabled: enabled)
    end
end
