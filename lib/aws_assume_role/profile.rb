require 'keyring'

module AWSAssumeRole

    class Profile

        require 'logger'

        # Class methods for dispatch to individual Profile strategy

        @implementations = {}
        @named_profiles  = {}
        @config_file     = '-'

        class << self
            attr_accessor :implementations
            attr_accessor :named_profiles
            attr_accessor :config_file
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

        def self.load_config_file(config_path)
            @config_file = config_path
            self.parse_config(File.open(config_path))
        end

        def self.parse_config(yaml)

            require 'yaml'

            profiles = YAML::load(yaml)
            profiles.each do |name,options|
                options['config_file'] = config_file
                options['name']        = name
                AWSAssumeRole::Profile.create(name,options)
            end

        end



        # Superclass for Profile strategies

        def set_env(prefix='')

            ENV["#{prefix}AWS_ACCESS_KEY_ID"]     = access_key_id
            ENV["#{prefix}AWS_SECRET_ACCESS_KEY"] = secret_access_key

            if self.respond_to?(:session_token)
                ENV["#{prefix}AWS_SESSION_TOKEN"] = session_token
            end

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

        def keyring_key
            "#{@options['config_file']}|#{@options['name']}"
        end

        def session(duration=3600)

            require 'hash_dot'
            require 'time'

            # See if we already have a non-expired session cached in this
            # object.

            unless @session.nil?
                expiry = Time.parse(@session[:credentials][:expiration])
                if expiry > Time.now
                    return @session
                end
                @session = nil
            end

            # TODO Should we create just one of these as a class variable?
            keyring = Keyring.new

            # See if there's a non-exipred session cached in the keyring
            serialised_stored_session = keyring.get_password('AWSAssumeRole', keyring_key)
            if serialised_stored_session
                @session = JSON.parse(serialised_stored_session, symbolize_names: true)

                puts "Session: #{@session}"

                expiry = Time.parse(@session[:credentials][:expiration])
                if expiry > Time.now
                    return @session.to_dot
                end
                @session = nil
            end

            unless mfa_arn.nil?
                @session = sts_client.get_session_token(
                    duration_seconds: duration,
                    serial_number:    mfa_arn,
                    token_code:       token_code,
                ).to_h
            else
                @session = sts_client.get_session_token(
                    duration_seconds: duration,
                ).to_h
            end

            # Convert expiry time from Time to string for similar reasons
            puts @session.inspect
            @session[:credentials][:expiration] = @session[:credentials][:expiration].to_s

            # Store session in keyring
            keyring.set_password('AWSAssumeRole', keyring_key, @session.to_json)

            return @session.to_h.to_dot

        end

    end

end
