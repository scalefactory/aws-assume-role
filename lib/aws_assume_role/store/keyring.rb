require_relative "includes"
require_relative "serialization"
require_relative "../configuration"
require_relative "../logging"

module AwsAssumeRole::Store::Keyring
    include AwsAssumeRole
    include AwsAssumeRole::Store
    include AwsAssumeRole::Logging

    module_function

    KEYRING_KEY = "AwsAssumeRole".freeze

    def semaphore
        @semaphore ||= Mutex.new
    end

    def keyrings
        @keyrings ||= {}
    end

    def try_backend_plugin
        return if AwsAssumeRole::Config.backend_plugin.blank?
        logger.info "Attempting to load #{AwsAssumeRole::Config.backend_plugin} plugin"
        require AwsAssumeRole::Config.backend_plugin
    end

    def keyring(backend = AwsAssumeRole::Config.backend)
        keyrings[backend] ||= begin
            try_backend_plugin
            klass = backend ? "Keyring::Backend::#{backend}".constantize : nil
            logger.debug "Initializing #{klass} backend"
            ::Keyring.new(klass)
        end
    end

    def fetch(id, backend: nil)
        logger.debug "Fetching #{id} from keyring"
        fetched = keyring(backend).get_password(KEYRING_KEY, id)
        raise Aws::Errors::NoSuchProfileError if fetched == "null" || fetched.nil? || !fetched
        JSON.parse(fetched, symbolize_names: true)
    end

    def delete_credentials(id, backend: nil)
        semaphore.synchronize do
            keyring(backend).delete_password(KEYRING_KEY, id)
        end
    end

    def save_credentials(id, credentials, expiration: nil, backend: nil)
        credentials_to_persist = Serialization.credentials_to_hash(credentials)
        credentials_to_persist[:expiration] = expiration if expiration
        semaphore.synchronize do
            keyring(backend).delete_password(KEYRING_KEY, id)
            keyring(backend).set_password(KEYRING_KEY, id, credentials_to_persist.to_json)
        end
    end
end
