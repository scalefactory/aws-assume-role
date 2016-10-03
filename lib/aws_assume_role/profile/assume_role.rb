# AWSAssumeRole
module AWSAssumeRole

    class Profile

        # A Profile implementation for assuming roles using STS
        class AssumeRole < Profile

            register_implementation('assume_role', self)

            @sts_client = nil
            @role       = nil
            @options    = nil
            @name       = nil

            def default_options
                {
                    'parent'   => 'default',
                    'duration' => 3600,
                }
            end

            def initialize(name, options = {})

                require 'aws-sdk'

                @options = default_options.merge(options)
                @name    = name

                # TODO: validate options

            end

            def sts_client

                return @sts_client unless @sts_client.nil?
                # TODO: check session validity?

                parent = AWSAssumeRole::Profile.get_by_name(@options['parent'])

                @sts_client = Aws::STS::Client.new(
                    access_key_id:     parent.session.access_key_id,
                    secret_access_key: parent.session.secret_access_key,
                    session_token:     parent.session.session_token,
                )

                @sts_client

            rescue Aws::Errors::MissingRegionError

                STDERR.puts 'No region was given. \
                    Set one in the credentials file or environment'
                exit -1 # rubocop:disable Lint/AmbiguousOperator

            end

            def role_credentials

                # Check for non-expired session cached here

                unless @role_credentials.nil?

                    return @role_credentials unless @role_credentials.expired?
                    @role_credentials.delete_from_keyring(keyring_key)

                end

                # See if here's a non-exipred session in the keyring

                @role_credentials = Credentials.load_from_keyring(keyring_key)

                unless @role_credentials.nil?

                    return @role_credentials unless @role_credentials.expired?
                    @role_credentials.delete_from_keyring(keyring_key)

                end

                role = sts_client.assume_role(
                    role_arn:          @options['role_arn'],
                    role_session_name: name, # use something else?
                    duration_seconds:  @options['duration'],
                )

                @role_credentials =
                    Credentials.create_from_sdk(role.credentials)

                @role_credentials.store_in_keyring(keyring_key)

                @role_credentials

            end

            def access_key_id
                role_credentials.access_key_id
            end

            def secret_access_key
                role_credentials.secret_access_key
            end

            def session_token
                role_credentials.session_token
            end

            def mfa_arn
                @options['mfa_arn'] || nil
            end

            def use
                set_env if @options['set_environment']
            end

        end

    end

end
