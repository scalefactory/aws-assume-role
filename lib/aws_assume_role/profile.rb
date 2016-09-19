module AWSAssumeRole

    class Profile

        require 'logger'

        # Class methods for dispatch to individual Profile strategy

        @implementations = {}
        @named_profiles  = {}

        class << self
            attr_accessor :implementations
            attr_accessor :named_profiles
        end

        def self.log
            if @logger.nil?
                @logger = Logger.new(STDERR)
            end
            @logger
        end

        def self.register_implementation(type,impl)
            log.info("Registering implementation for type '#{type}': #{impl}")
            AWSAssumeRole::Profile.implementations[type] = impl
        end

        Dir.glob(File.expand_path('profile/*.rb', File.dirname(__FILE__))).each do |profile_class|
            require profile_class
        end

        def self.create(name,options)

            unless options.key?('type')
                options['type'] = 'basic'
            end

            if implementations.key?(options['type'])
                i = implementations[options['type']].new(name, options)
                named_profiles[name] = i
                return i
            end

            STDERR.puts "No implementation for profiles of type '#{options['type']}'"
            exit -1

        end

        def self.get_by_name(name)
            unless named_profiles.key?(name)
                STDERR.puts "No profile '#{name}' found"
                exit -1
            end
            named_profiles[name]
        end


        # Superclass for Profile strategies

        def set_env(prefix='')

            ENV["#{prefix}AWS_ACCESS_KEY_ID"]     = access_key_id
            ENV["#{prefix}AWS_SECRET_ACCESS_KEY"] = secret_access_key
            #ENV["#{prefix}AWS_SESSION_TOKEN"]     = session_token

        end

        def access_key_id
            raise NotImplementedError
        end

        def secret_access_key
            raise NotImplementedError
        end

        def sts_client
            raise NotImplementedError
        end

        def mfa_arn
            raise NotImplementedError
        end

        def name
            @name
        end

        def use
            raise NotImplementedError
        end

        def token_code
            puts "Enter MFA token code for #{mfa_arn}"
            token_code = gets
            token_code.chomp!
        end

        def session(duration=3600)

            return @session unless @session.nil?

            unless mfa_arn.nil?
                @session = sts_client.get_session_token(
                    duration_seconds: duration,
                    serial_number:    mfa_arn,
                    token_code:       token_code,
                )
            else
                @session = sts_client.get_session_token(
                    duration_seconds: duration,
                )
            end

            return @session

        end

    end

end
