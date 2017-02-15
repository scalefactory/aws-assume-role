require "dry-types"
module AwsAssumeRole
    module Types
        ACCESS_KEY_REGEX = //
        SECRET_ACCESS_KEY_REGEX = //
        ARN_REGEX = %r{arn:[\w+=\/,.@-]+:[\w+=\/,.@-]+:[\w+=\/,.@-]*:[0-9]+:[\w+=,.@-]+(\/[\w+=\/,.@-]+)*}
        MFA_REGEX = %r{arn:aws:iam::[0-9]+:mfa\/([\w+=,.@-]+)*|automatic}
        ROLE_REGEX = %r{arn:aws:iam::[0-9]+:role\/([\w+=,.@-]+)*}
        REGION_VALIDATOR = proc { filled? & str? & format?(REGION_REGEX) }
        ACCESS_KEY_VALIDATOR = proc { filled? & str? & format?(ACCESS_KEY_REGEX) }
        SECRET_ACCESS_KEY_VALIDATOR = proc { filled? & str? & format?(SECRET_ACCESS_KEY_REGEX) }
        Dry = Dry::Types.module
        REGION_REGEX = /^(us|eu|ap|sa|ca)\-\w+\-\d+$|^cn\-\w+\-\d+$|^us\-gov\-\w+\-\d+$/
        ::Dry::Types.register_class(::Aws::Credentials)
        AwsAssumeRole::Types::Credentials = ::Dry::Types["aws.credentials"]
        AwsAssumeRole::Types::Region = Dry::Strict::String.constrained(
            format: REGION_REGEX,
        )

        AwsAssumeRole::Types::MfaSerial = Dry::Strict::String.constrained(
            format: MFA_REGEX,
        )
    end
end
