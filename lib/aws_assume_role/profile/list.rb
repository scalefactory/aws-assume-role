# AWSAssumeRole
module AWSAssumeRole

    class Profile

        # A Profile implementation which aggregates other profiles.
        # Used to setenv for multiple credentials, but with different
        # prefixed.
        class List < Profile

            include Logging

            register_implementation('list', self)

            @options = nil
            @name    = nil

            def initialize(name, options)

                # TODO: validate options

                @options = options
                @name    = name

            end

            def use

                @options['list'].each do |i|
                    puts i['name']

                    profile = Profile.get_by_name(i['name'])
                    profile.set_env(i['env_prefix'])
                end

            end

        end

    end

end
