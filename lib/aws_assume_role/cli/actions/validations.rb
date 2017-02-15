require_relative "includes"

module AwsAssumeRole::Cli::Actions::Validations
    REGION_REGEX = /^(us|eu|ap|sa|ca)\-\w+\-\d+$|^cn\-\w+\-\d+$|^us\-gov\-\w+\-\d+$/
    ACCESS_KEY_REGEX = /[\w]+/
    SECRET_ACCESS_KEY_REGEX = //
    ARN_REGEX = %r{arn:[\w+=\/,.@-]+:[\w+=\/,.@-]+:[\w+=\/,.@-]*:[0-9]+:[\w+=,.@-]+(\/[\w+=\/,.@-]+)*}
    MFA_REGEX = %r{arn:aws:iam::[0-9]+:mfa\/([\w+=,.@-]+)*|automatic}
    ROLE_REGEX = %r{arn:aws:iam::[0-9]+:role\/([\w+=,.@-]+)*}
    ROLE_SESSION_NAME_REGEX = /[\w+=,.@-]*/
    EXTERNAL_ID_REGEX = %r{[\w+=,.@:\/-]*}
    REGION_VALIDATOR = proc { filled? & str? & format?(REGION_REGEX) }
    ACCESS_KEY_VALIDATOR = proc { filled? & str? & format?(ACCESS_KEY_REGEX) & min_size?(16) & max_size?(32) }
    SECRET_ACCESS_KEY_VALIDATOR = proc { filled? & str? & format?(SECRET_ACCESS_KEY_REGEX) }
end
