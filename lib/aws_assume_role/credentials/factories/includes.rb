require "dry-initializer"
require "dry-types"
require "aws-sdk"
require_relative "../../logging"
require_relative "../../vendored/aws"
require_relative "../../../aws_assume_role"

module AwsAssumeRole
    module Credentials
        module Factories
            Types = Dry::Types.module
            include AwsAssumeRole
            include AwsAssumeRole::Logging
            include AwsAssumeRole::Vendored::Aws
        end
    end
end
