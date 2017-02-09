# Mixin to provide global logging object
module AwsAssumeRole
    module Logging
        require "logger"

        module ClassMethods
            def logger
                @logger ||= Logger.new($stderr)
            end
        end

        def self.included(base)
            base.extend ClassMethods
        end
    end
end
