module AWSAssumeRole

    class Profile::AssumeRole < Profile

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

            # TODO validate options

        end

        def sts_client

            return @sts_client unless @sts_client.nil?
            # TODO check session validity?

            parent = AWSAssumeRole::Profile.get_by_name(@options['parent'])

            @sts_client = Aws::STS::Client.new(
                access_key_id:     parent.session.access_key_id,
                secret_access_key: parent.session.secret_access_key,
                session_token:     parent.session.session_token,
            )

            @sts_client

        rescue Aws::Errors::MissingRegionError

            STDERR.puts 'No region was given. Set one in the credentials file or environment'
            exit -1

        end

        def role

            return @role unless @role.nil?

            @role =  sts_client.assume_role(
                role_arn:          @options['role_arn'],
                role_session_name: name, # use something else?
                duration_seconds:  @options['duration'],
            )

            @role

        end

        def role_credentials

            return @role_credentials unless @role_credentials.nil?

            # TODO load from keyring, check validity

            puts role.credentials.inspect

            @role_credentials = role.credentials
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
            if @options['set_environment']
                set_env
            end
        end

    end

end
