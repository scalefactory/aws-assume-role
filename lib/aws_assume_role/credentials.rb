# AWSAssumeRole
module AWSAssumeRole

    require 'keyring'
    require 'json'

    # Represents credentials, used for serialising into keychain
    class Credentials

        def self.load_from_keyring(key)

            keyring = Keyring.new
            json_session = keyring.get_password('AWSAssumeRole', key)

            return nil unless json_session

            hash = JSON.parse(json_session, symbolize_names: true)
            return nil unless hash

            hash[:expiration] = Time.parse(hash[:expiration])

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

        def store_in_keyring(key)
            keyring = Keyring.new
            keyring.set_password('AWSAssumeRole', key, @credentials.to_json)
        end

        def delete_from_keyring(key)
            keyring = Keyring.new
            keyring.delete_password('AWSAssumeRole', key)
        end

        def expired?
            @credentials[:expiration] <= Time.now
        end

    end

end
