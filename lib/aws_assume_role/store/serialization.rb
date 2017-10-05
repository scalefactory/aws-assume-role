# frozen_string_literal: true

module AwsAssumeRole::Store::Serialization
    module_function

    def credentials_from_hash(credentials)
        creds_for_deserialization = credentials.respond_to?("[]") ? credentials : credentials_to_hash(credentials)
        Aws::Credentials.new(creds_for_deserialization[:access_key_id],
                             creds_for_deserialization[:secret_access_key],
                             creds_for_deserialization[:session_token])
    end

    def credentials_to_hash(credentials)
        {
            access_key_id: credentials.access_key_id,
            secret_access_key: credentials.secret_access_key,
            session_token: credentials.session_token,
        }
    end
end
