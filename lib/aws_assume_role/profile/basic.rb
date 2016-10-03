# AWSAssumeRole
module AWSAssumeRole

    class Profile

        # Profile implementation which takes credentials from either
        # passed options, from the environment, or from .aws/credentials
        # file (per the standard behaviour of Aws::STS::Client)
        class Basic < Profile

            register_implementation('basic', self)

            @sts_client = nil
            @options    = nil
            @name       = nil

            def initialize(name, options = {})

                require 'aws-sdk'

                # TODO: validate options
                # TODO: default region?

                @options = options
                @name    = name

            end

            def sts_client

                return @sts_client unless @sts_client.nil?

                if @options.key?('access_key_id') &&
                   @options.key?('secret_access_key')

                    @sts_client = Aws::STS::Client.new(
                        access_key_id:     @options['access_key_id'],
                        secret_access_key: @options['secret_access_key'],
                        region:            @options['region'],
                    )

                else

                    @sts_client = Aws::STS::Client.new

                end

                @sts_client

            rescue Aws::Errors::MissingRegionError

                STDERR.puts 'No region was given. \
                    Set one in the credentials file or environment'
                exit -1 # rubocop:disable Lint/AmbiguousOperator

            end

            def access_key_id
                @options['access_key_id']
            end

            def secret_access_key
                @options['secret_access_key']
            end

            def mfa_arn
                @options['mfa_arn'] || nil
            end

        end

    end

end
