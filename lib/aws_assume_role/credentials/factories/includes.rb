# frozen_string_literal: true

require_relative "../includes"
require_relative "../../logging"
require_relative "../../vendored/aws"
require_relative "../../../aws_assume_role"

module AwsAssumeRole::Credentials
    module Factories
        Types = Dry.Types(default: :nominal)
        include AwsAssumeRole
        include AwsAssumeRole::Logging
        include AwsAssumeRole::Vendored::Aws
    end
end
