# AwsAssumeRole
module AwsAssumeRole
    class Profile
        # Profile implementation which takes credentials from either
        # passed options, from the environment, or from .aws/credentials
        # file (per the standard behaviour of Aws::STS::Client)
        class Basic < Profile
            include Logging

            register_implementation("basic", self)

            @sts_client = nil
            @options    = nil
            @name       = nil

            def initialize(name, options = {})
                require "aws-sdk"

                @options = options
                @name    = name
            end

            def sts_client
                logger.debug("Calling STS client")

                return @sts_client unless @sts_client.nil?

                if @options.key?("profile")

                    logger.info("Loading profile #{@options['profile']} from ~/.aws/credentials")
                    # Attempt to load with profile name suplied
                    @sts_client = Aws::STS::Client.new(
                        profile: @options["profile"],
                    )

                elsif access_key_id && secret_access_key

                    logger.debug("Access Key: #{access_key_id}")
                    logger.debug("Secret Key: #{secret_access_key}")
                    logger.debug("Region: #{region}")

                    @sts_client = Aws::STS::Client.new(
                        access_key_id:     access_key_id,
                        secret_access_key: secret_access_key,
                        region:            region,
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

            def basic_credentials
                logger.debug("Loading basic credentials")
                # Check for profile creds in keyring first
                @basic_credentials = Credentials.load_from_keyring("#{keyring_key}|basic")

                return @basic_credentials unless @basic_credentials.nil?

                creds = {
                    access_key_id: ENV["AWS_ACCESS_KEY_ID"],
                    secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
                }

                if creds[:access_key_id].nil? || creds[:secret_access_key].nil?
                    STDERR.puts "No AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY " \
                                "found in the environment."
                    exit -1 # rubocop:disable Lint/AmbiguousOperator
                end

                creds[:region] = if @options["region"].nil?
                                     ENV["AWS_DEFAULT_REGION"]
                                 else
                                     @options["region"]
                                 end

                @basic_credentials = AwsAssumeRole::Credentials.new(creds)

                @basic_credentials
            end

            def access_key_id
                @options["access_key_id"] || basic_credentials.access_key_id
            end

            def secret_access_key
                @options["secret_access_key"] || basic_credentials.secret_access_key
            end

            def region
                @options["region"] || basic_credentials.region
            end

            def remove
                Credentials.new.delete_from_keyring(keyring_key)
                Credentials.new.delete_from_keyring("#{keyring_key}|basic")
            end

            def add
                if @options["profile"]
                    puts "WARNING: Storing credentials but a profile is specified and used for #{@name}"
                end
                if @options["access_key_id"] || @options["secret_access_key"]
                    puts "WARNING: Storing credentials but they are specified in config for #{@name}"
                end

                @basic_credentials = Credentials.load_from_keyring("#{keyring_key}|basic")
                new_creds = fetch_credentials
                @basic_credentials.delete_from_keyring(keyring_key) unless @basic_credentials.nil?
                @basic_credentials = AwsAssumeRole::Credentials.new(new_creds)
                @basic_credentials.store_in_keyring("#{keyring_key}|basic")
            end

            def fetch_credentials
                puts "Enter your AWS_ACCESS_KEY_ID: "
                id = STDIN.gets
                id.chomp!
                puts "Enter your AWS_SECRET_ACCESS_KEY: "
                secret = STDIN.gets
                secret.chomp!
                puts "Enter a AWS Region:"
                region = STDIN.gets
                region.chomp!

                creds = {
                    access_key_id: id,
                    secret_access_key: secret,
                    region: region,
                }
                creds
            end
        end
    end
end
