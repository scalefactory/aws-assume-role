# frozen_string_literal: true

require_relative "includes"
require_relative "repository"
require_relative "../../profile_configuration"

class AwsAssumeRole::Credentials::Factories::AbstractFactory
    include AwsAssumeRole
    include AwsAssumeRole::Credentials::Factories
    include AwsAssumeRole::Logging

    Dry::Types.register("aws.sharedcredentials", Aws::SharedCredentials)
    attr_reader :credentials, :region, :profile, :role_arn

    def initialize(_options)
        raise "Not implemented"
    end

    def self.type(str)
        @type = Types::Strict::Symbol.enum(:credential_provider, :second_factor_provider, :instance_role_provider)[str]
        register_if_complete
    end

    def self.priority(i)
        @priority = Types::Strict::Int[i]
        register_if_complete
    end

    def self.register_if_complete
        return unless @type && @priority
        Repository.register_factory(self, @type, @priority)
    end
end
