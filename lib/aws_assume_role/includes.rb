require "i18n"
require "keyring"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/hash/keys"
require "active_support/core_ext/object/json"
require "aws-sdk"
require "aws-sdk-core/ini_parser"
require "dry-configurable"
require "dry-initializer"
require "dry-validation"
require "dry-types"
require "English"
require "gli"
require "highline"
require "inifile"
require "json"
require "logger"
require "pastel"
require "thread"
require "time"

module AwsAssumeRole
    module_function

    def shared_config
        enabled = ENV["AWS_SDK_CONFIG_OPT_OUT"] ? false : true
        @shared_config ||= SharedConfigWithKeyring.new(config_enabled: enabled)
    end
end
