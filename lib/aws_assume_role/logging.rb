# Mixin to provide global logging object
module AWSAssumeRole

    module Logging

        require 'logger'

        class << self

            def logger
                @logger ||= Logger.new($stderr)
            end

            attr_writer :logger

        end

        def self.included(base)

            class << base

                def logger # rubocop:disable Lint/NestedMethodDefinition
                    Logging.logger
                end

            end

        end

        def logger
            Logging.logger
        end

    end

end
