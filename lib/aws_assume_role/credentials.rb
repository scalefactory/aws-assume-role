# AWSAssumeRole
module AWSAssumeRole
    require "keyring"
    require "json"
    require "time"

    # Represents credentials, used for serialising into keychain
    class Credentials
        include Logging

        def self.load_from_keyring(key)
            logger.debug("Keyring: load '#{key}'")

            keyring = Keyring.new
            json_session = keyring.get_password("AWSAssumeRole", key)

            unless json_session
                logger.info("No JSON session data in keyring")
                return nil
            end

            hash = JSON.parse(json_session, symbolize_names: true)

            unless hash
                logger.info('Couldn\'t parse keyring data as JSON')
                return nil
            end

            hash[:expiration] = Time.parse(hash[:expiration]) unless hash[:expiration].nil?

            logger.debug("Loaded #{hash}")
            AWSAssumeRole::Credentials.new(hash)
        end

        def self.create_from_sdk(object)
            raise TypeError unless object.is_a?(Aws::STS::Types::Credentials)
            AWSAssumeRole::Credentials.new(object.to_h)
        end

        @credentials = nil

        def initialize(hash)
            @credentials = hash
        end

        def secret_access_key
            @credentials[:secret_access_key]
        end

        def access_key_id
            @credentials[:access_key_id]
        end

        def session_token
            @credentials[:session_token]
        end

        def expiration
            @credentials[:expiration]
        end

        def region
            @credentials[:region]
        end

        def store_in_keyring(key)
            keyring = Keyring.new
            logger.debug("Keyring: store '#{key}' with #{@credentials.to_json}")
            keyring.set_password("AWSAssumeRole", key, @credentials.to_json)
        end

        def delete_from_keyring(key)
            keyring = Keyring.new
            logger.debug("Keyring: delete '#{key}'")
            keyring.delete_password("AWSAssumeRole", key)
        end

        def expired?
            logger.debug("Checking expiry: #{@credentials[:expiration]} "\
                         "<= Time.now")
            @credentials[:expiration] <= Time.now
        end
    end
end
