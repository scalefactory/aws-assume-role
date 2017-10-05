# frozen_string_literal: true

require_relative "includes"
require_relative "configuration"
module AwsAssumeRole::Logging
    module ClassMethods
        def logger
            @logger ||= begin
                logger = Logger.new($stderr)
                logger.level = AwsAssumeRole::Config.log_level
                ENV["GLI_DEBUG"] = "true" if AwsAssumeRole::Config.log_level.zero?
                logger
            end
        end
    end

    module InstanceMethods
        def logger
            self.class.logger
        end
    end

    def self.included(base)
        base.extend ClassMethods
        base.include InstanceMethods
    end
end
