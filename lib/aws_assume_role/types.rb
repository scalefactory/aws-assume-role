require_relative "includes"
module AwsAssumeRole
    module Types
        Dry = Dry::Types.module

        ::Dry::Types.register_class(::Aws::Credentials)
        AwsAssumeRole::Types::Credentials = ::Dry::Types["aws.credentials"]

        ACCESS_KEY_REGEX = /[\w]+/
        ACCESS_KEY_VALIDATOR = proc { filled? & str? & format?(ACCESS_KEY_REGEX) & min_size?(16) & max_size?(32) }
        ARN_REGEX = %r{arn:[\w+=\/,.@-]+:[\w+=\/,.@-]+:[\w+=\/,.@-]*:[0-9]+:[\w+=,.@-]+(\/[\w+=\/,.@-]+)*}
        EXTERNAL_ID_REGEX = %r{[\w+=,.@:\/-]*}
        MFA_REGEX = %r{arn:aws:iam::[0-9]+:mfa\/([\w+=,.@-]+)*|automatic}
        REGION_REGEX = /^(us|eu|ap|sa|ca)\-\w+\-\d+$|^cn\-\w+\-\d+$|^us\-gov\-\w+\-\d+$/
        REGION_VALIDATOR = proc { filled? & str? & format?(REGION_REGEX) }
        ROLE_REGEX = %r{arn:aws:iam::[0-9]+:role\/([\w+=,.@-]+)*}
        ROLE_SESSION_NAME_REGEX = /[\w+=,.@-]*/
        SECRET_ACCESS_KEY_REGEX = //
        SECRET_ACCESS_KEY_VALIDATOR = proc { filled? & str? & format?(SECRET_ACCESS_KEY_REGEX) }

        AwsAssumeRole::Types::Region = Dry::Strict::String.constrained(
            format: REGION_REGEX,
        )

        AwsAssumeRole::Types::MfaSerial = Dry::Strict::String.constrained(
            format: MFA_REGEX,
        )
    end
end
