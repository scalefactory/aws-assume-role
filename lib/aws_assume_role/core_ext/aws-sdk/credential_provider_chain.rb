require_relative "../../credentials/factories/default_chain_provider"
Aws.const_set :CredentialProviderChain, AwsAssumeRole::Credentials::Factories::DefaultChainProvider
