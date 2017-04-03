require_relative "includes"
require "set"

class AwsAssumeRole::Credentials::Providers::AssumeRoleCredentials
    include AwsAssumeRole::Vendored::Aws::CredentialProvider
    include AwsAssumeRole::Vendored::Aws::RefreshingCredentials

    # @option options [required, String] :role_arn
    # @option options [required, String] :role_session_name
    # @option options [String] :policy
    # @option options [Integer] :duration_seconds
    # @option options [String] :external_id
    # @option options [STS::Client] :client
    #
    #

    STS_KEYS = %i[role_arn role_session_name policy duration_seconds external_id client credentials region].freeze

    def initialize(options = {})
        client_opts = {}
        @assume_role_params = {}
        options.each_pair do |key, value|
            if self.class.assume_role_options.include?(key)
                @assume_role_params[key] = value
            else
                next unless STS_KEYS.include?(key)
                client_opts[key] = value
            end
        end
        @client = client_opts[:client] || ::Aws::STS::Client.new(client_opts)
        super
    end

    # @return [STS::Client]
    attr_reader :client

    private

    def refresh
        c = @client.assume_role(@assume_role_params).credentials
        @credentials = ::Aws::Credentials.new(
            c.access_key_id,
            c.secret_access_key,
            c.session_token,
        )
        @expiration = c.expiration
    end

    class << self
      # @api private
      def assume_role_options
          @aro ||= begin
              input = ::Aws::STS::Client.api.operation(:assume_role).input
              Set.new(input.shape.member_names)
          end
      end
      end
end
