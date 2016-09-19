module AWSAssumeRole

    class Profile::List < Profile

        register_implementation('list', self)

        @options = nil
        @name    = nil

        def initialize(name, options)

            # TODO validate options

            @options = options
            @name    = name

        end

        def use

            @options['list'].each do |i|

                puts i['name']

                profile = AWSAssumeRole::Profile.get_by_name(i['name'])
                profile.set_env(i['env_prefix'])

            end

        end

    end

end
