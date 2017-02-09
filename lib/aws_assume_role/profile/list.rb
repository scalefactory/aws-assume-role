# AwsAssumeRole
module AwsAssumeRole
    class Profile
        # A Profile implementation which aggregates other profiles.
        # Used to setenv for multiple credentials, but with different
        # prefixed.
        class List < Profile
            include Logging

            register_implementation("list", self)

            @options = nil
            @name    = nil

            def initialize(name, options)
                # TODO: validate options

                @options = options
                @name    = name
            end

            def use
                @options["list"].each do |i|
                    profile = Profile.get_by_name(i["name"])

                    next unless @options["set_environment"]

                    profile.set_env(i["env_prefix"]) if i["env_prefix"]

                    next unless i["map_names"]
                    i["map_names"].each do |name, env|
                        call = name.to_sym
                        if profile.respond_to?(call)
                            ENV[env] = profile.send(call)
                        end
                    end
                end
            end
        end
    end
end
