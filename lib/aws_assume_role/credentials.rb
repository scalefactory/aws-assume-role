module AWSAssumeRole

    require 'keyring'
    require 'json'

    class Credentials

        def self.load_from_keyring(key)

            keyring = Keyring.new
            json_session = keyring.get_password('AWSAssumeRole',key)

            if !json_session
                return nil
            end

            hash = JSON.parse(json_session, symbolize_names: true)
            if !hash
                return nil
            end

            hash[:expiration] = Time.parse(hash[:expiration])

            AWSAssumeRole::Credentials.new(hash)

        end

        def self.create_from_sdk(object)

            unless object.is_a?(Aws::STS::Types::Credentials)
                raise TypeError
            end

            AWSAssumeRole::Credentials.new(object.to_h)

        end

        @credentials = nil

        def initialize(hash)
            @credentials = hash
        end

        def secret_access_key
            return @credentials[:secret_access_key]
        end

        def access_key_id
            return @credentials[:access_key_id]
        end

        def session_token
            return @credentials[:session_token]
        end

        def expiration
            return @credentials[:expiration]
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
