require_relative "includes"
require_relative "abstract_factory"

class AwsAssumeRole::Credentials::Factories::Repository
    include AwsAssumeRole::Credentials::Factories

    SubFactoryRepositoryType = Types::Hash.schema(Types::Coercible::Int => Types::Strict::Array)

    FactoryRepositoryType = Types::Hash.schema(
        credential_provider: SubFactoryRepositoryType,
        second_factor_provider: SubFactoryRepositoryType,
        instance_role_provider: SubFactoryRepositoryType,
    )

    def self.factories
        repository.keys.map { |t| [t, flatten_factory_type_list(t)] }.to_h
    end

    def self.repository
        @repository ||= FactoryRepositoryType[
            credential_provider: {},
            second_factor_provider: {},
            instance_role_provider: {},
        ]
    end

    def self.register_factory(klass, type, priority)
        repository[type][priority] ||= []
        repository[type][priority] << klass
    end

    def self.flatten_factory_type_list(type)
        repository[type].keys.sort.map { |x| @repository[type][x] }.flatten
    end
end
