# AWSAssumeRole
module AWSAssumeRole

    class Profile

        # Profile implementation which takes credentials from either
        # passed options, from the environment, or from .aws/credentials
        # file (per the standard behaviour of Aws::STS::Client)
        class Basic < Profile

            include Logging

            register_implementation('basic', self)

            @sts_client = nil
            @options    = nil
            @name       = nil

            def initialize(name, options = {})

                require 'aws-sdk'

                @options = options
                @name    = name

            end

            def sts_client

                return @sts_client unless @sts_client.nil?

                if @options.key?('access_key_id') &&
                   @options.key?('secret_access_key')

                    if @options.key?('region')

                        @sts_client = Aws::STS::Client.new(
                            access_key_id:     @options['access_key_id'],
                            secret_access_key: @options['secret_access_key'],
                            region:            @options['region'],
                        )

                    else

                        @sts_client = Aws::STS::Client.new(
                            access_key_id:     @options['access_key_id'],
                            secret_access_key: @options['secret_access_key'],
                        )

                    end
                
                elsif @options.key?('profile')

                    logger.info("Loading profile #{@options['profile']} from ~/.aws/credentials")
                    # Attempt to load with profile name suplied
                    @sts_client = Aws::STS::Client.new(
                        profile: @options['profile'],
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

            def region
                @options['region']
            end

        end

    end

end
